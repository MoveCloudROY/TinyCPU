int *a;

bool check(int);

int bs(int l, int r) {
    while (l <= r) {
        int mid = (l + r) >> 1;
        if (check(mid)) {
            // ...
            r = mid;
        } else {
            l = mid + 1;
        }
    }
    return r;
}