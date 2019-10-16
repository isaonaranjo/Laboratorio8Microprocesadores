// María Isabel Ortiz Naranjo
#include <stdio.h>  // le agregué el #
#include <stdlib.h> 
#include <cuda_runtime.h>

#define N 16 

__global__ void kernel( int *a, int *b, int *c ) // Agregué *b
{
	int myID = threadIdx.x + blockDim.x * blockIdx.x;
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
int main(int argc, char** argv)
{
	cudaStream_t stream1, stream2;
	
	int *a1, *b1, *c1; 									// stream 1 mem ptrs
	int *a2, *b2, *c2; 									// stream 2 mem ptrs
	int *dev_a1, *dev_b1, *dev_c1; 						// stream 1 mem ptrs
	int *dev_a2, *dev_b2, *dev_c2; 						// stream 2 mem ptrs
	
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
	
	for (int i =0; i<N; i++){
		a1[i]= i;
		b1[i]= a1[i] + i;

		a2[i]= i;
		b2[i]= a1[i] * i;

	}

	for(int i=0;i < N;i+= N*2) { // loop over data in chunks
	// interweave stream 1 and steam 2
		
		cudaMemcpyAsync(dev_a1,a1,N*sizeof(int),cudaMemcpyHostToDevice,stream1); // Faltaba los Async en la memoria cuda
		cudaMemcpyAsync(dev_a2,a2,N*sizeof(int),cudaMemcpyHostToDevice,stream2); // Faltaba los Async en la memoria cuda
		cudaMemcpyAsync(dev_b1,b1,N*sizeof(int),cudaMemcpyHostToDevice,stream1); // Faltaba los Async en la memoria cuda
		cudaMemcpyAsync(dev_b2,b2,N*sizeof(int),cudaMemcpyHostToDevice,stream2); // Faltaba los Async en la memoria cuda
		
		kernel<<<(int)ceil(N/1024)+1,1024,0,stream1>>>(dev_a1,dev_b1,dev_c1);
		kernel2<<<(int)ceil(N/1024)+1,1024,0,stream2>>>(dev_a2,dev_b2,dev_c2);
		
		cudaMemcpyAsync(c1,dev_c1,N*sizeof(int),cudaMemcpyDeviceToHost,stream1);
		cudaMemcpyAsync(c2,dev_c2,N*sizeof(int),cudaMemcpyDeviceToHost,stream2);
	}

	cudaStreamSynchronize(stream1); // Agregue Synchronize 
	cudaStreamSynchronize(stream2); 
	
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
	cudaStreamDestroy(stream1); // Agregue un Destroy
	cudaStreamDestroy(stream2);

	return 0;
	
}