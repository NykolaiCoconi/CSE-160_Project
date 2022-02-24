#define AM_NEIGHBOR 62

configuration NDiscoveryC{
  provides interface NDiscovery;
}

implementation{
    components NDiscoveryP;
    components new SimpleSendC(AM_NEIGHBOR);
    components new AMReceiverC(AM_NEIGHBOR);

    NDiscoveryP.neighborList = neighborListC;


    // External Wiring
    NDiscovery = NDiscoveryP.NDiscovery;

    components new TimerMilliC() as myTimerC; //create a new timer with alias “myTimerC”
    NDiscoveryP.neigbordiscoveryTimer -> myTimerC; //Wire the interface to the component
    NDiscoveryP.FloodSender -> FloodingC.FloodSender;

}