chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'SocketIORemoteService', ->
  describe '#rpc', ->
    it 'should emit the given payload as rpc request over socket.io-client', ->
      socketIORemoteService = require './socketio_remote_service_client'
      sandbox = sinon.sandbox.create()

      socketIOClientStub = sandbox.stub()
      socketIOClientStub.on = sandbox.stub()
      socketIOClientStub.emit = sandbox.stub()

      rpcPayload =
        some: 'payload'

      socketIORemoteService.initialize socketIOClientStub
      socketIORemoteService.rpc rpcPayload, ->
      expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.true
