int *a;
void qsort(int l, int r) {
    if (l >= r)
        return;
    int key = a[l];
    int i = l, j = r;
    while (i < j) {
        // 从小到大
        while (i < j && key < a[j])
            --j;
        a[i] = a[j];
        while (i < j && key > a[i])
            ++i;
        a[j] = a[i];
    }
    a[i] = key;
    qsort(l, i - 1);
    qsort(i + 1, r);
}