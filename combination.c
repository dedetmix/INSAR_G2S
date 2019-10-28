#include <stdio.h>
// N.Isya 2017.11.01

int main (int argc, char **argv, int *arr)
{
  //remove dummy result
  char filename[] = "result_combination.txt";
  remove(filename);

  FILE *indate, *result_combination;
  //read date file
  indate = fopen(argv[1],"r+");

    if (indate == NULL) {
        printf("Couldn't open the file.");
        return 1;
    }

    char tmp1[200];
    int k;
	k=0;
        while(fscanf(indate, "%s", &tmp1[0])) 
	{
		if (feof(indate)) break;
                arr[k]=atoi(tmp1);
                k=k+1;
        }
	printf ("number of dates = %i \n", k); 


  //make simple combination and write on file
  result_combination =  fopen("result_combination.txt","a");
  //int arr[] = {1, 2, 3};
  int i,j,*data;
  data=arr;
  for (i=0; i<k;i++)
      for (j=0; j<k; j++) {
  if (arr[i]!=data[j] && arr[i]<data[j])
//  printf ("hasil: %d %d \n",arr[i], data[j]);
  fprintf(result_combination,"%d %d \n",arr[i], data[j]);
  }
  return 0;
}
