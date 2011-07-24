{
  This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 of the License.
   
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
}

// Copyright (c) 2010 2011 - J. Aldo G. de Freitas Junior

{$MODE DELPHI}

Unit
	SyncQueue;

Interface

Uses
	Classes,
	SysUtils,
	SyncObjs,
	ActorMessages,
	ContNrs;

Type
	// Synchronized Queue

	TCustomSynchronizedQueue = Class
	Private
		fQueue        : TObjectQueue;
		fSynchronizer : TMultiReadExclusiveWriteSynchronizer;
		fSignal       : TEventObject;
		fActive       : Boolean;
	Public
		Function WaitFor(Const aTimeout : Cardinal): TWaitResult;
		Function Count : Integer; 
		Function AtLeast(Const aCount : Integer): Boolean;
		Procedure Push(Const aObject : TCustomActorMessage);
		Function Pop : TCustomActorMessage;
		Constructor Create;
		Destructor Destroy; Override;
	End;

Implementation

// TCustomSynchronizedQueue

Function TCustomSynchronizedQueue.WaitFor(Const aTimeout : Cardinal): TWaitResult;
Begin
	Result := fSignal.WaitFor(aTimeout);
End;

Function TCustomSynchronizedQueue.Count : Integer;
Begin
	Try
		fSynchronizer.BeginRead;
		Result := fQueue.Count;
	Finally
		fSynchronizer.EndRead;
	End;
End;

Function TCustomSynchronizedQueue.AtLeast(Const aCount : Integer): Boolean;
Begin
	Try
		fSynchronizer.BeginRead;
		Result := fQueue.AtLeast(aCount);
	Finally
		fSynchronizer.EndRead;
	End;
End;

Procedure TCustomSynchronizedQueue.Push(Const aObject : TCustomActorMessage);
Begin
	Try
		fSynchronizer.BeginWrite;
		fQueue.Push(aObject);
		fSignal.SetEvent;
	Finally
		fSynchronizer.EndWrite;
	End;
End;

Function TCustomSynchronizedQueue.Pop: TCustomActorMessage;
Begin
	Try
		fSynchronizer.BeginWrite;
		Result := (fQueue.Pop As TCustomActorMessage)
	Finally
		fSynchronizer.EndWrite;
	End;
End;

Constructor TCustomSynchronizedQueue.Create;
Begin
	Inherited Create;
	fQueue := TObjectQueue.Create;
	fSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
	fSignal := TEventObject.Create(Nil, False, False, '');
	fActive := True;
End;

Destructor TCustomSynchronizedQueue.Destroy;
Begin
	While fQueue.AtLeast(1) Do
		fQueue.Pop.Free;
	FreeAndNil(fQueue);
	FreeAndNil(fSynchronizer);
	FreeAndNil(fSignal);
	Inherited Destroy;
End;

End.