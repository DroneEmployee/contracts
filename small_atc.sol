import 'atc_interface';

contract ResponseListener is MessageHandler {
    address[] clients;
    
    function newRequest(address _addr) returns (uint32) {
        clients[clients.length++] = _addr;
        return uint32(clients.length);
    }

    function incomingMessage(Message _msg) {
        RouteResponse res = RouteResponse(_msg);
        Aircraft(clients[res.id() - 1]).setRoute(res);
    }
}

contract SmallATC is ROSCompatible, ATC {
    Publisher   route_request;
    Publisher   route_remover;
    ResponseListener listener;
    
    event NewRequest(uint32 id);
    
    function SmallATC() {
        route_request = mkPublisher('/small_atc/route/request',
                                    'dron_common_msgs/RouteRequest');
        route_remover = mkPublisher('/small_atc/route/remove',
                                    'std_msgs/UInt32');
        listener = new ResponseListener();
        mkSubscriber('/small_atc/route/response',
                     'dron_common_msgs/RouteResponse',
                     listener);
    }
    
    function makeRoute(SatFix[] _checkpoints) {
        uint32 id = listener.newRequest(msg.sender);
        NewRequest(id);
        route_request.publish(new RouteRequest(_checkpoints, id));
    }
    
    function dropRoute(uint32 _id) {
        route_remover.publish(new StdUInt32(_id));
    }
}