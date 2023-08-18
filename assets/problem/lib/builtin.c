// 统计一个数据的二进制有多少个为 1 的比特位
int builtin_popcount(unsigned int data) {
    // Method 1:
    unsigned int tcnt = 0;
    while (data) {
        data = data & (data - 1);
        ++tcnt;
    }
    return tcnt;
}

// 检查数字的奇偶校验。如果数字具有奇校验（设置位的奇数）
// 则返回 true(1)，否则返回偶校验（设置位的偶数）的 false(0)
int builtin_parity(unsigned int data) {
    data ^= data >> 16;
    data ^= data >> 8;
    data ^= data >> 4;
    data ^= data >> 2;
    data ^= data >> 1;
    return data & 1;
    /*
        n ^= n >> 16;
        n ^= n >> 8;
        n ^= n >> 4;
        n &= 0x0F; // Keep only the lowest 4 bits
        return (0x6996 >> n) & 1;
    */
}

// 从右往左数，统计一个数据尾部比特位等于 0 的个数
int builtin_ctz(unsigned int data) {
    if (data == 0)
        return sizeof(data) * 8;

    int count = 0;
    while ((data & 1) == 0) {
        data >>= 1;
        count++;
    }
    return count;
    /*
    static const int trailing_zeros_lookup[16] = {
        32, 0, 1, 32, 2, 32, 32, 32, 3, 32, 32, 32, 32, 32, 32, 32
    };

    int count = 0;
    while ((n & 15) == 0) {
        n >>= 4;
        count += 4;
    }
    return count + trailing_zeros_lookup[n & 15];
    */
}

// 从左往右数遇到第一个比特位等于 1 之前已经遇到了多少个 0
int builtin_clz(unsigned int data) {
    if (data == 0)
        return sizeof(data) * 8; // Assuming 32-bit integers

    int count = 0;
    while ((data & (1 << 31)) == 0) {
        count++;
        data <<= 1;
    }
    return count;
    /*
    int count = 0;

    if ((x & 0xFFFF0000) == 0) { count += 16; x <<= 16; }
    if ((x & 0xFF000000) == 0) { count += 8; x <<= 8; }
    if ((x & 0xF0000000) == 0) { count += 4; x <<= 4; }
    if ((x & 0xC0000000) == 0) { count += 2; x <<= 2; }
    if ((x & 0x80000000) == 0) { count += 1; }

    return count;
    */
}

// 查找整数中最低有效（最右边）设置位
int builtin_ffs(unsigned int data) {
    if (data == 0)
        return 0;

    int position = 1;
    while ((data & 1) == 0) {
        data >>= 1;
        position++;
    }
    return position;
    /*
        return builtin_ctz(x) + 1;
    */
}

int builtin_lg(unsigned int data) {
    int position = 0;

    while (data >>= 1) {
        position++;
    }

    return position;
}
// Please complete the above function with GCC -fno-builtin option. You should use the fastest algorithm for each one.