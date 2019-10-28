
/*********************************************
UNIVERSIDAD DEL VALLE DE GUATEMALA
CC3056 - Programación de Microprocesadores

Autores: 
Josue Sagastume  18173
Isabel Ortiz  18176
Mario Perdomo 18029

Fecha: 29/10/2019
Archivo: CUDA_Proyecto
Descripcion: 
Determina el promedio de los datos obtenidos del 
sensor UV GUVA - S12SD en un determinado rango de tiempo.
**********************************************/

// Librerias a utilizar
#include <stdio.h> 
#include <stdlib.h> 
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <fstream>
#include <sstream> 
#include<bits/stdc++.h> 

//rangos de tiempo a utilizar::
// 6 a 10, 10 a 2 y 2 a 6 

#define N (6250) //Hilos creados por la cantidad de datos por cada stream 
#define THREADS_PER_BLOCK (6250) //Hilos por bloque
#define N_BLOCKS (N/THREADS_PER_BLOCK) // Bloques creados

// Esta funcion sirve para obtener promedios de los datos obtenidos en un rango de tiempo
// IMPORTANTE: no se como haremos para parametrizar el tiempo... - Mario
// Lo deje pendiente para hablar con ustedes - Mario
/*__global__ void operation( int *a, int *b, int *c )
{
	int myID = threadIdx.x + blockDim.x * blockIdx.x; // indice 
	// Solo trabajan N hilos
	if (myID < N)
	{
		c[myID] = a[myID] + b[myID];
	}
}
__global__ void kernel2( int *a, int *b, int *c )
{
	// Originalmente no funcionaba, ya que faltaba el Id del bloque a utilizar
	int myID = threadIdx.x + blockDim.x* blockIdx.x;

	// Solo trabajan N hilos
	if (myID < N)
	{
		c[myID] = a[myID] * b[myID];
	}
}
__global__ void kernel3( int *a, int *b, int *c )
{
	// Originalmente no funcionaba, ya que faltaba el Id del bloque a utilizar
	int myID = threadIdx.x + blockDim.x* blockIdx.x;

	// Solo trabajan N hilos
	if (myID < N)
	{
		c[myID] = a[myID] * b[myID];
	}
}
__global__ void kernel4( int *a, int *b, int *c )
{
	int myID = threadIdx.x + blockDim.x* blockIdx.x;

	// Solo trabajan N hilos
	if (myID < N)
	{
		c[myID] = a[myID] * b[myID];
	}
}
*/

int main(int argc, char** argv)
{
	//Se hace cuatro streams para realizar operaciones asincronas
	cudaStream_t stream1, stream2, stream3, stream4;
	//Se instancia un array de strings
	vector <string> data;
	// Instancia para abrir archivos .txt
	ifstream inFile;
	inFile.open("test.txt");
	//Programación defensiva si no existe
    if (!inFile) {
        cout << "El archivo no fue abierto correctamente... \n";
        exit(1); // termina el programa 

    while (inFile >> x) {
    	//Agarra todos los string del txt y lo pasa a un vector para luego convertirlo en int o float
    	//fuente: https://www.geeksforgeeks.org/array-strings-c-3-different-ways-create/
        data.push_back(x);
    }
    
    inFile.close();
	
	int *a1, *b1, *c1; 									// stream 1 mem ptrs
	int *a2, *b2, *c2; 									// stream 2 mem ptrs
	int *a3, *b3, *c3; 									// stream 3 mem ptrs
	int *a4, *b4, *c4; 									// stream 4 mem ptrs

	int *dev_a1, *dev_b1, *dev_c1; 						// stream 1 mem ptrs
	int *dev_a2, *dev_b2, *dev_c2; 						// stream 2 mem ptrs
	int *dev_a3, *dev_b3, *dev_c3; 						// stream 3 mem ptrs
	int *dev_a4, *dev_b4, *dev_c4; 						// stream 4 mem ptrs
	
	//stream 1
	cudaMalloc( (void**)&dev_a1, N * sizeof(int) );
	cudaMalloc( (void**)&dev_b1, N * sizeof(int) );
	cudaMalloc( (void**)&dev_c1, N * sizeof(int) );

	cudaHostAlloc( (void**)&a1, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&b1, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&c1, N * sizeof(int), cudaHostAllocDefault);
	
	//stream 2
	cudaMalloc( (void**)&dev_a2, N * sizeof(int) );
	cudaMalloc( (void**)&dev_b2, N * sizeof(int) );
	cudaMalloc( (void**)&dev_c2, N * sizeof(int) );

	cudaHostAlloc( (void**)&a2, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&b2, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&c2, N * sizeof(int), cudaHostAllocDefault);

	//Stream 3
	cudaMalloc( (void**)&dev_a3, N * sizeof(int) );
	cudaMalloc( (void**)&dev_b3, N * sizeof(int) );
	cudaMalloc( (void**)&dev_c3, N * sizeof(int) );

	cudaHostAlloc( (void**)&a3, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&b3, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&c3, N * sizeof(int), cudaHostAllocDefault);

	//Stream 4
	cudaMalloc( (void**)&dev_a4, N * sizeof(int) );
	cudaMalloc( (void**)&dev_b4, N * sizeof(int) );
	cudaMalloc( (void**)&dev_c4, N * sizeof(int) );

	cudaHostAlloc( (void**)&a4, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&b4, N * sizeof(int), cudaHostAllocDefault);
	cudaHostAlloc( (void**)&c4, N * sizeof(int), cudaHostAllocDefault);

	// Falta definir como se estaran entregando los datos
	for (int i =0; i<N; i++){
		a1[i]= i;
		b1[i]= a1[i] + i;

		a2[i]= i;
		b2[i]= a1[i] * i;

	}

	for(int i=0;i < N;i+= N*2) { // loop over data in chunks
	// interweave stream 1 and steam 2
		// Faltaba los asyncs en la memoria cuda
		cudaMemcpyAsync(dev_a1,a1,N*sizeof(int),cudaMemcpyHostToDevice,stream1);
		cudaMemcpyAsync(dev_a2,a2,N*sizeof(int),cudaMemcpyHostToDevice,stream2);
		// Faltaba los asyncs en la memoria cuda
		cudaMemcpyAsync(dev_b1,b1,N*sizeof(int),cudaMemcpyHostToDevice,stream1);
		cudaMemcpyAsync(dev_b2,b2,N*sizeof(int),cudaMemcpyHostToDevice,stream2);
		
		kernel<<<(int)ceil(N/1024)+1,1024,0,stream1>>>(dev_a1,dev_b1,dev_c1);
		kernel2<<<(int)ceil(N/1024)+1,1024,0,stream2>>>(dev_a2,dev_b2,dev_c2);
		
		cudaMemcpyAsync(c1,dev_c1,N*sizeof(int),cudaMemcpyDeviceToHost,stream1);
		cudaMemcpyAsync(c2,dev_c2,N*sizeof(int),cudaMemcpyDeviceToHost,stream2);
	}

	cudaStreamSynchronize(stream1); //Faltaba un synchronize para stream 1
	cudaStreamSynchronize(stream2); // wait for stream2 to finish
	
	printf("Stream 1 \n");
	printf("a1 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",a1[i]);
	}
	printf("b1 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",b1[i]);
	}
	printf("c1 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",c1[i]);
	}
	printf("Stream 2 \n");
	printf("a2 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",a2[i]);
	}
	printf("b2 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",b2[i]);
	}
	printf("c2 \n");
	for (int i =0; i<N; i++){
		printf("%d \n",c2[i]);
	}

	// Destruye todo los streams
	cudaStreamDestroy(stream1); 
	cudaStreamDestroy(stream2);
	cudaStreamDestroy(stream3);
	cudaStreamDestroy(stream4);

	return 0;

	
}