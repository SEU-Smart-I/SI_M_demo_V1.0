from multiprocessing.connection import Client
import numpy as np

PORT = 6000
ADDRESS = ('localhost', PORT)


def send_array(flag, height, width, img_data): 
    flag = int(flag)
    height = int(height)
    width = int(width)
    #print('height: {} width: {}'.format(height, width))
    #print('img data type: ', img_data.dtype, ' shape:', img_data.shape)
    img_bytes = img_data.tobytes('C')
    data_shape = (height, width)
    with Client(ADDRESS, authkey=None, family='AF_INET') as conn:
        # send module flag to server
        conn.send(flag)
        # send img shape to server
        conn.send(data_shape)
        # send img data
        conn.send(img_bytes)
        # receive model predict result data
        while not conn.poll():
            pass
        mask_bytes = conn.recv()
        # convert result data into numpy array
        mask = np.frombuffer(mask_bytes, dtype=np.uint8)
        mask = np.reshape(mask, newshape=data_shape)
        return mask * 255


if __name__ == '__main__':
    for _ in range(5):
        m = input("please input msg:")
        h = 512
        w = 512
        arr = np.random.randint(low=0, high=255, size=(h, w), dtype=np.uint16)
        ret = send_array(h, w, arr)
        print('receive from server', ret.shape)