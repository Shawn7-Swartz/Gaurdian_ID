import cv2
cap = cv2.VideoCapture(0)
while True:
    
    ok, frame  = cap.read()
    if not ok:
        print("Failed to capturee")
        break
    cv2.imshow("Live camera working, testt", frame)
    
    
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break
    

cap.release()
cap.destroyAllWindows()