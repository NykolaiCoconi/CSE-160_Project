#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module FloodingP{
    provides interface Flooding;
    uses interface SimpleSend as Flooder;
    uses interface SimpleSend as Sender;
    
    uses interface Receive as MReceiver;
    uses interface Receive as Receiver;
    uses interface List<pack> as Records;
}

implementation {
    pack sendPackage;
    void makePackage(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    void addtoQueue(pack *Package);
    bool packageHistory(pack* Package);
    uint16_t nodeSeq = 0;

    command error_t Flooder.send(pack *Package, uint16_t dest){
        dbg(FLOODING_CHANNEL, "Sending from Flood\n");
        Package.src = TOS_NODE_ID;
        Package.seq = nodeSeq++;
        Package.TTL = MAX_TTL;
        addtoQueue(Package);
        call Sender.send(*Package, AM_BROADCAST_ADDR);
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
                if(contents -> protocol == PROTOCOL_PING){      //Sending Reply
                    dbg(FLOODING_CHANNEL, "%d replying to %d \n", contents -> dest, contents ->src);
                    //Update Package
                    uint16_t temp = contents -> src;
                    contents -> src = contents -> dest;
                    contents -> dest = temp;
                    contents -> protocol = PROTOCOL_PINGREPLY;
                    addtoQueue(contents);       //Make sure it can run, add to records
                    //send package back
                    call Flooder.send(*contents, contents -> dest);
                    return signal MReceiver.receive(msg, payload, len);
                }
                else if(contents -> protocol == PROTOCOL_PINGREPLY){ //Just a reply good to remove now
                    dbg(FLOODING_CHANNEL, "%d got reply from %d for message \n", contents -> dest, contents ->src);
                    return msg;
                }
            }
            else{   //Decrement TTL and continue
                contents -> TTL--;

                if (contents -> TTL == 0){         //Ran out of time
                    dbg(FLOODING_CHANNEL, "TTL: %d\n", contents-> TTL);
                    return msg;
                }

                call Sender.send(*contents, AM_BROADCAST_ADDR);
            }
            dbg(FLOODING_CHANNEL, "Something went wrong \n");
            return msg;
        }
    }


    void makePackage(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length){      //Setup a package
        //Package -> origin = src;      might use this don't know yet
        Package -> dest = dest;
        Package -> src = src;
        Package -> seq = seq;
        Package -> TTL = TTL;
        Package -> protocol = protocol;
        memcpy(Package -> payload, payload, length);
        dbg(GENERAL_CHANNEL, "Made Package: \n      Src: %hhu Dest: %hhu Seq: %hhu TTL: %hhu Protocol:%hhu  Payload: %s\n", src, dest, seq, TTL, protocol, payload);
    }

    bool packageHistory(pack* Package){     //Checks duplicates
        uint16_t i;
        for(i = 0; i < call Records.size(); i++){
            pack comparison = call Records.get(i);
            if((Package -> dest == comparison.dest) && (Package -> src == comparison.src) && (Package -> seq == comparison.seq) && (Package -> protocol == comparison.protocol)){
                return TRUE;
            }
        }
        return FALSE;
    }

    void addtoQueue(pack *Package){
        if(call Records.isFull()){          //check if record queue is full if it is make room using List takes out first packet to be used. 
            call Records.popfront();        
        }
        call Records.pushback(*Package);    //Adding Packet to Records using List
    }
}