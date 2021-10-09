# -*- coding: utf-8 -*-
"""
Created on Wed May 26 17:02:33 2021

@author: user
"""
import os
os.environ['KMP_DUPLICATE_LIB_OK']='True'
from tensorflow.keras.models import load_model
import numpy as np
import skimage.io as io
from skimage import measure,transform, morphology
#import tensorflow as tf
#gpus= tf.config.experimental.list_physical_devices('GPU') 
#tf.config.experimental.set_memory_growth(gpus[0], True)


    
def single_frame_processing(frame, model):
    frame = np.reshape(frame,(1,)+frame.shape+(1,))
    results = model.predict(frame)
    frame_out = results[0,:,:,0]>0.5   
    frame_out = morphology.remove_small_objects(frame_out, 500)
    frame_out = np.uint8(frame_out*255)
    return  frame_out#,np.array(loc)


    
