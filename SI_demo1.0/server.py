import numpy as np
from multiprocessing.connection import Listener
import tensorflow as tf
from tensorflow.keras.models import load_model
from skimage import morphology
import os

# set tensorflow log level 3 means only show error message
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
#os.environ['CUDA_VISIBLE_DEVICES'] = '0'
gpus = tf.config.experimental.list_physical_devices('GPU')
if len(gpus) > 0 :
    tf.config.experimental.set_visible_devices(devices=gpus[0], device_type='GPU')
    tf.config.experimental.set_memory_growth(gpus[0], True)

PORT = 6000
ADDRESS = ('localhost', PORT)
MODEL_PATH = r'E:\\SIdemos\\SI_demo_host1.1\\u_model\\ssim_att_n10'#E:\\Cell_Task\\code4matlab\\u_model\\model4matlab
MODEL_TISSUE_PATH = r'E:\\SIdemos\\SI_demo_host1.1\\u_model\\model4tissue2'

def start_server():
    model = load_model(MODEL_PATH, compile = False)
    print('model4cell is loaded')
    model_tissue = load_model(MODEL_TISSUE_PATH, compile = False)
    print('model4tissue is loaded')
    with Listener(ADDRESS, authkey=None, family='AF_INET') as listener:
        while True:
            with listener.accept() as conn:
                # receive module flag(0/1)
                module_flag = conn.recv()
                # receive img shape
                # print('receive shape')
                img_shape = conn.recv()
                data_shape = (1, ) + img_shape + (1, )
                # receive img data
                # print('receive img data')
                img_bytes = conn.recv()
                # convert data into numpy array
                data_ = np.frombuffer(img_bytes, dtype=np.float32)
                data_ = np.reshape(data_, newshape=data_shape)
                
                #print('predict')
                # call model do prediction
                if module_flag:
                    pred = model.predict(data_)
                    pred = np.squeeze(pred)
                    pred = morphology.remove_small_objects(pred>0.5, 900)
                else:
                    pred = model_tissue.predict(data_)
                    pred = np.squeeze(pred)>0.5
                # generate img mask
                result = np.array(pred, dtype=np.uint8)
                result_bytes = result.tobytes('C')
                conn.send(result_bytes)


if __name__ == '__main__':
    start_server()
