

configuration DiscoveryC{
// Use SimpleSendC & SimpleSendP for basic tasks for sending packets
}
configuration CommandHandlerC{
    provides interface CommandHandler;
}

implementation{
    components DiscoveryP;
    Discovery = DiscoveryP;
   // Discovery = DiscoveryP.Discovery;
   
}