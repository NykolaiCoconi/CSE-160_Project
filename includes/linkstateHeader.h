#ifndef linkstateHeader_H
#define linkstateHeader_H

enum{
	LINKSTATE_MAX = 25
};

typedef nx_struct lsHeader{
	nx_uint16_t neighbor;
	nx_uint8_t cost;
	nx_uint8_t src;
}lsHeader;

#endif
