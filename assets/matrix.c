void matrix(int a[128][128],int b[128][128],int c[128][128],unsigned int n) {
    unsigned int i,j,k;
    for (k=0; k!=n; k++) {
        for (i=0; i!=n; i++) {
            int r = a[i][k];
            for (j=0; j!=n; j++)
                c[i][j] += r * b[k][j];
        }
    }
}

int main() {
	int * a = (int*)0x80400000;
	int * b = (int*)0x80410000;
	int * c = (int*)0x80420000;
	matrix(a, b, c, 96);
	return 0;
} 
