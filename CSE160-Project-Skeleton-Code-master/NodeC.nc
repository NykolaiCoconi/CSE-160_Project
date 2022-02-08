/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}

implementation {
    components MainC;
    components NodeP;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    NodeP -> MainC.Boot;

    NodeP.Receive -> GeneralReceive;

    components ActiveMessageC;
    NodeP.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    NodeP.Sender -> SimpleSendC;

    components CommandHandlerC;
    NodeP.CommandHandler -> CommandHandlerC;
}
