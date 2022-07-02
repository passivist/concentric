import numpy as np
import cv2 as cv
from pythonosc.udp_client import SimpleUDPClient
from null_preview import *
from picamera2 import *
import time

dt = 0.025

## OSC Setup
ip = "127.0.0.1"
port = 57120
client = SimpleUDPClient(ip, port)  # Create client

# Camera Setup
size = 16
picam2 = Picamera2()
preview = NullPreview(picam2)
picam2.configure(picam2.preview_configuration(main={"size": (640, 480)}))
picam2.start()

def spiralOrder(matrix):
    if (len(matrix) == 0):
        return result
 
    sizeX = len(matrix)
    sizeY = len(matrix[0])

    result = [[0 for i in range(sizeY)] for j in range(sizeX)]
    seen = [[0 for i in range(sizeY)] for j in range(sizeX)]
    directions_rows = [0, 1, 0, -1]
    directions_columns = [1, 0, -1, 0]
    x = 0
    y = 0
    direction_index = 0

    # Iterate from 0 to Rows * Columns - 1
    for i in range(sizeY):
        for j in range(sizeX):
            result[i][j] = matrix[x][y]
            seen[x][y] = True
            counter_rows = x + directions_rows[direction_index]
            counter_cols = y + directions_columns[direction_index]
            #print(f"x: {x}, y: {y}, counter_rows: {counter_rows}, counter_cols: {counter_cols}")
            if ( 0 <= counter_rows and
                 counter_rows < sizeY and
                 0 <= counter_cols and
                 counter_cols < sizeX and
                 not(seen[counter_rows][counter_cols]) ):
                x = counter_rows
                y = counter_cols
            else:
                direction_index = (direction_index + 1) % 4
                x += directions_rows[direction_index]
                y += directions_columns[direction_index]
    return np.array(result)


while True:
    frame picam2.capture_array()
    frame = spiralOrder(frame)

    client.send_message("/image", frame.tolist())
    

# When everything done, release the capture
cap.release()
cv.destroyAllWindows()