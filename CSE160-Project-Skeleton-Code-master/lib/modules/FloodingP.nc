#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module FloodingP{
    provides interface Flooding;
    uses interface SimpleSend as Sender;
    uses interface Receive as Receiver;
    uses interface List<pack> as Records;
    uses interface Discovery;
}

implementation {
    pack sendPackage;
    void makePackage(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    void addtoQueue(pack *package);
    bool packageHistory(pack* package);
    uint16_t nodeSeq = 0;

    command error_t Flooding.send(pack *package, uint16_t dest){
        dbg(FLOODING_CHANNEL, "Sending from Flood\n");
        package.src = TOS_NODE_ID;
        package.protocol = PROT_PING;
        package.seq = nodeSeq++;
        package.TTL = MAX_TTL;
        call Recieve.send(package, AM_BROADCAST_ADDR);
    }

    event message_t *Receiver.receive(message_t * msg, void *payload, uint8_t len){
        dbg(FLOODING_CHANNEL, "Packet received in Flooding\n");
        if (len == sizeof(pack)){
            pack *contents = (pack*)payload;

            if ((contents -> src == TOS_NODE_ID) || packageHistory(msg) == TRUE){ //Looped around/Duplicate
                dbg(FLOODING_CHANNEL, "Dropping packet.\n");
                return msg;
            }
            else if(TOS_NODE_ID == contents -> dest){       //Check if reached destination
                dbg(FLOODING_CHANNEL, "Reached Destination %d from %d.\n", contents -> dest, contents -> src);
                if(contents -> protocal == PROT_PING){      //Sending Reply
                    dbg(FLOODING_CHANNEL, "%d replying to %d \n", contents -> dest, contents ->src);

                    addtoQueue(contents);       //Make sure it can run, add to records

                    //send package back


                }
            }
            else if (contents -> TTL == 0){         //Ran out of time
                dbg(FLOODING_CHANNEL, "TTL: %d\n", contents-> TTL);
                return msg;
            }
            else if(TOS_NODE_ID != contents -> dest){

                //Continue Flood
                //relay to Discovery

            }
            return msg;
        }
    }


    void makePackage(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){      //Setup a package
        Package -> dest = dest;
        Package -> src = src;
        Package -> seq = seq;
        Package -> TTL = TTL;
        Package -> protocol = protocol;
        memcpy(Package -> payload, payload, length);
        dbg(GENERAL_CHANNEL, "Made Package: \n      Src: %hhu Dest: %hhu Seq: %hhu TTL: %hhu Protocol:%hhu  Payload: %s\n", src, dest, seq, TTL, protocol, payload);
    }

    bool packageHistory(pack* package){     //Checks duplicates
        uint16_t i;
        for(i = 0; i < call Records.size(); i++){
            pack comparison = call Records.get(i);
            if((package -> dest == comparison.dest) && (package -> src == comparison.src) && (package -> seq == comparison.seq) && (package -> protocol == comparison.protocol)){
                return TRUE;
            }
        }
        return FALSE;
    }

    void addtoQueue(pack *package){
        if(call Records.isFull()){          //check if record queue is full if it is make room using List
            call Records.popfront();
        }
        call Records.pushback(*package);    //Adding Packet to Records using List
    }
}