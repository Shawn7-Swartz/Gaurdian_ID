import cv2
import mediapipe as mp

face_dectection = mp.solutions.face_detection

#For close-range faces like selfie camera, model_selection=0
dectector = face_dectection.FaceDetection(
    model_selection=0,
    min_detection_confidence=0.6
)

cap = cv2.VideoCapture(0)
while True:
    ok, frame = cap.read()
    if not ok:
        break
# OpenCv takes BGR while mediapipe taked RGB, hence need to convert
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results  = dectector.process(frame_rgb)



    if results.detections:
        h,w,_ = frame.shape
        for i in results.detections:
            box = i.location_data.relative_bounding_box
            x = int(box.xmin*w)
            y = int(box.ymin*h)
            bw = int(box.width*w)
            bh = int(box.height*h)
            cv2.rectangle(frame, (x,y), (x+bw, y+bh), (0,255,0),2)

    cv2.imshow("Face dectection test", frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
cap.release()
cap.destroyAllWindows()