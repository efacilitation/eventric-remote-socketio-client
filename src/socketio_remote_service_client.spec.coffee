chai   = require 'chai'
expect = chai.expect
sinon  = require 'sinon'

describe 'SocketIORemoteService', ->
  socketIORemoteService = null
  sandbox = null
  socketIOClientStub = null

  beforeEach ->
    sandbox = sinon.sandbox.create()
    socketIOClientStub = sandbox.stub()
    socketIOClientStub.on = sandbox.stub()
    socketIOClientStub.emit = sandbox.stub()

    socketIORemoteService = require './socketio_remote_service_client'


  describe '#rpc', ->
    it 'should emit the given payload as rpc request over socket.io-client', ->
      socketIORemoteService.initialize socketIOClientStub
      rpcPayload =
        some: 'payload'
      socketIORemoteService.rpc rpcPayload, ->
      expect(socketIOClientStub.emit.calledWith 'RPC_Request', rpcPayload).to.be.true


  describe '#initialize', ->
    it 'should register a callback for RPC_Response which makes use of setTimeout', ->
      sandbox.stub global, 'setTimeout'
      socketIOClientStub.on.yields()
      socketIORemoteService.initialize socketIOClientStub
      expect(socketIOClientStub.on.calledWith 'RPC_Response').to.be.true
      expect(global.setTimeout.calledOnce).to.be.true


