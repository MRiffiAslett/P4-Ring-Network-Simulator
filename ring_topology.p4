/*
 * ring_topology.p4
 *
 * A minimal P4 program for ring-based forwarding.
 * We parse Ethernet and IPv4, then match on the IPv4 destination
 * to decide whether to forward locally or pass to the next switch in the ring.
 */

#include <core.p4>
#include <v1model.p4>

#define HOST1_IP 0x0A000101 /* 10.0.1.1 in hex */
#define HOST2_IP 0x0A000201 /* 10.0.2.1 in hex */
#define HOST3_IP 0x0A000301 /* 10.0.3.1 in hex */

typedef bit<48> macAddr_t;
typedef bit<32> ipv4Addr_t;

// ----------------------------------------------------------------------------
// Headers and Parsers
// ----------------------------------------------------------------------------

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ipv4Addr_t srcAddr;
    ipv4Addr_t dstAddr;
}

struct metadata_t {
    /* empty for now */
}

struct standard_metadata_t {
    bit<9>   ingress_port;
    bit<9>   egress_spec;
    bit<9>   egress_port;
    bit<9>   clone_session_id;
    bit<32>  instance_type;
    bit<1>   drop;
    bit<3>   recirculate_group_id;
    bit<16>  mcast_grp;
    // ... Additional fields ...
}

// Parser states
parser MyParser(packet_in packet,
                out ethernet_t hdr_ethernet,
                out ipv4_t hdr_ipv4,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr_ethernet);
        transition select(hdr_ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr_ipv4);
        transition accept;
    }
}

// ----------------------------------------------------------------------------
// Ingress Processing
// ----------------------------------------------------------------------------

control Ingress(inout ethernet_t hdr_ethernet,
                inout ipv4_t hdr_ipv4,
                inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {

    // We'll use a table to decide the output port based on IPv4 dstAddr
    table ipv4_lpm {
        key = {
            hdr_ipv4.dstAddr: exact;
        }
        actions = {
            forward;
            drop;
        }
        size = 3;
        default_action = drop();
    }

    action forward(bit<9> port, macAddr_t dst_mac) {
        // Overwrite the ethernet dst MAC with the next hop's MAC
        hdr_ethernet.dstAddr = dst_mac;
        // Keep the src MAC as the switch’s MAC in a real scenario, 
        // but for simplicity let's just not rewrite it here.
        standard_metadata.egress_spec = port;
    }

    action drop() {
        standard_metadata.egress_spec = 0; // 0 typically means "drop" in bmv2
    }

    apply {
        if (hdr_ethernet.etherType == 0x0800) {
            ipv4_lpm.apply();
        } else {
            // For non-IPv4 traffic, just drop or send to CPU, etc.
            drop();
        }
    }
}

// ----------------------------------------------------------------------------
// Egress Processing (optional in this simple demo)
// ----------------------------------------------------------------------------

control Egress(inout ethernet_t hdr_ethernet,
               inout ipv4_t hdr_ipv4,
               inout metadata_t meta,
               inout standard_metadata_t standard_metadata) {
    apply { }
}

// ----------------------------------------------------------------------------
// Deparser
// ----------------------------------------------------------------------------

control MyDeparser(packet_out packet,
                   in ethernet_t hdr_ethernet,
                   in ipv4_t hdr_ipv4) {

    apply {
        packet.emit(hdr_ethernet);
        if (hdr_ethernet.etherType == 0x0800) {
            packet.emit(hdr_ipv4);
        }
    }
}

// ----------------------------------------------------------------------------
// Switch
// ----------------------------------------------------------------------------

V1Switch(MyParser(),
         Ingress(),
         Egress(),
         MyDeparser()) main;
