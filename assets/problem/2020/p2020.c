#pragma GCC optimize("Ofast", "unroll-loops")

int main() {
    unsigned int *addr = (unsigned int *)0x80400000;
    unsigned int  cnt  = 0;
    for (int i = 1; i <= 0x31111; ++i) {
        unsigned int tcnt = 0, x = i;
        while (x) {
            x = x & (x - 1);
            ++tcnt;
        }
        cnt += tcnt;
    }
    *addr = cnt;
    return 0;
}