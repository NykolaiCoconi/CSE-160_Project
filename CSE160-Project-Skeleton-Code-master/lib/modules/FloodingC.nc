configuration FloodingC{
    provides interface Flooding;
}

implementation {
    components FloodingP;
    components DiscoveryC;
    components new SimpleSendC(AM_PACK);    //Set channel of packets
    components new ListC(pack, 100);        //Make a list give type and max size

    Flooding = FloodingP;
    FloodingP.Sender -> SimpleSendC;
    FloodingP.Discovery -> DiscoveryC;
    FloodingP.Records -> ListC;
}