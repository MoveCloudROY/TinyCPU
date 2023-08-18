#pragma GCC optimize("Ofast")

char ***a = (char ***)0x80400000;
char   *b = (char *)0x80400000 + sizeof(char[3000][10][8]) / sizeof(char);

void quick_sort(int low, int high) {
    if (low >= high)
        return;
    char key = b[low];
    int  i = low, j = high;

    while (i < j) {
        while (i < j && key > b[j])
            --j;
        b[i] = b[j];
        while (i < j && key < b[i])
            ++i;
        b[j] = b[i];
    }
    b[i] = key;
    quick_sort(low, i - 1);
    quick_sort(i + 1, high);
}

int main() {

    for (int i = 0; i < 3000; ++i) {
        unsigned int scoreSum = 0;
        for (int j = 0; j < 10; ++j) {
            char     maxn    = a[i][j][0];
            char     minn    = a[i][j][0];
            char     subMaxn = -1;
            char     subMinn = 101;
            unsigned sum     = a[i][j][0];
            for (int k = 1; k < 8; ++k) {
                char tmp = a[i][j][k];
                sum += tmp;
                if (tmp >= maxn) {
                    subMaxn = maxn;
                    maxn    = tmp;
                } else if (tmp > subMaxn) {
                    subMaxn = tmp;
                }
                if (tmp <= minn) {
                    subMinn = minn;
                    minn    = tmp;
                } else if (tmp < subMinn) {
                    subMinn = tmp;
                }
            }
            sum      = sum - maxn - minn - subMaxn - subMinn;
            scoreSum = scoreSum + (sum / 4);
        }
        b[i] = scoreSum;
    }

    quick_sort(0, 2999);
    return 0;
}