struct state {
    bit<64> v0;
    bit<64> v1;
    bit<64> v2;
    bit<64> v3;
}


control HalfSipHash_2_4_32(
    in bit<64> key,
    inout bit<32> data
) {
    action sipRound(state s) {
        v0 = v0 + v1;
        v1 = v1 << 5;
        v1 = v1 ^ v0;
        v0 = v0 << 16;
        v2 = v2 + v3;
        v3 = v3 << 8;
        v3 = v3 ^ v2;
        v0 = v0 + v3;
        v3 = v3 << 7;
        v3 = v3 ^ v0;
        v2 = v2 + v1;
        v1 = v1 << 13;
        v1 = v1 ^ v2;
        v2 = v2 << 16;
    }

    action compression()

    apply {
        bit<32> k0 = key[31:0];
        bit<32> k1 = key[63:32];

        state s;
        s.v0 = k0 ^ 0x00000000;
        s.v1 = k1 ^ 0x00000000;
        s.v2 = k0 ^ 0x6c796765;
        s.v3 = k1 ^ 0x74656462;

        bit<8> m;

        m = data[0:8];
        s.v3 = s.v3 ^ m;
        sipRound(s);
        sipRound(s);
        s.v0 = s.v0 ^ m;

        m = data[8:16];
        s.v3 = s.v3 ^ m;
        sipRound(s);
        sipRound(s);
        s.v0 = s.v0 ^ m;

        m = data[16:24];
        s.v3 = s.v3 ^ m;
        sipRound(s);
        sipRound(s);
        s.v0 = s.v0 ^ m;

        m = data[24:32];
        s.v3 = s.v3 ^ m;
        sipRound(s);
        sipRound(s);
        s.v0 = s.v0 ^ m;

        s.v2 = s.v2 ^ 0x000000ff;
        sipRound(s);
        sipRound(s);
        sipRound(s);
        sipRound(s);

        data = s.v0 ^ s.v1 ^ s.v2 ^ s.v3;
    }
}
