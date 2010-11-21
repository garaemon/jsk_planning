(load "ros-callback-manager.l")
(load "add-msg-pgsql.l")

;; posedetectiondb -> tf client class
;;(load "package://euslib/jsk/kalmanlib.l")
(ros::roseus-add-msgs "posedetection_msgs")
;; get vector in vlist , that is least median distance
(defun lmeds-vector
  (vlist)
  (find-extream vlist
		#'(lambda(p)(let ((diffs (mapcar #'(lambda(p1)(distance p p1)) vlist)))
			      (elt (sort diffs #'<) (/ (length diffs) 2))))
		#'<=))
(defun lmeds-pose
  (pose-list)
  (make-coords :pos (lmeds-vector (send-all pose-list :pos))
	       :rot (quaternion2matrix (lmeds-vector (mapcar #'matrix2quaternion (send-all pose-list :rot))))))

(defclass posedetectiondb-client
  :super ros::ros-callback-object
  :slots (object time-stamp poselist))
(defmethod posedetectiondb-client
  (:init
   (obj)
   (setq object obj)
   (setq time-stamp (ros::time 0))
   (defvar *tfl* (instance ros::transform-listener :init))
   (defvar *tfb* (instance ros::transform-broadcaster :init))
   (send-super :init "ObjectDetection" posedetection_msgs::ObjectDetection :detection-cb))
  (:update-coords
   (coords &optional (relative :local))
   (when (< 5 (send (ros::time- (ros::time-now) time-stamp) :to-sec))
     (setq poselist nil))
   (setq time-stamp (ros::time-now))
   (when (not (equal coords (car poselist)))
     (push (send coords :copy-worldcoords) poselist)
     (when (< 20 (length poselist))
       (nreverse poselist)
       (pop poselist)
       (nreverse poselist)))
   (send object :move-to (lmeds-pose poselist) relative))
  (:detection-cb
   (msg)
   (dolist (object-msg (send msg :objects))
     (when (equal (string-left-trim "/" (send object-msg :type))
		  (string-left-trim "/" (send object :name)))
       ;; broadcast transform
       (send msg :header :stamp (ros::time 0))
       (let* ((pose (instance geometry_msgs::PoseStamped :init
			      :header (send msg :header)
			      :pose (send object-msg :pose)))
	      (coords (ros::tf-pose->coords (send pose :pose)))
	      (objcoords (send *tfl* :transform-pose
			       "/base_footprint" pose)))
	 (print (list 'detection-cb objcoords))
	 (when objcoords
	   (send self :update-coords objcoords :world)
	   (send *tfb* :send-transform object
		 "/base_footprint" (send object :name))
	   ;; insert detection raw result to DB
	   (insert-tf-table-by-coords
	    *db* (ros::time-now) (make-coords) objcoords
	    :source_id "/base_footprint" :target_id (send object :name))
	   )
	 ))))
  )

(defun init-posedetectiondb-client (objects)
  (let (clients)
    (dolist (obj objects)
      (push (instance posedetectiondb-client :init obj) clients))
    (ros::ros-info "initialize posedetection db client with ~A~%" (send-all objects :name))
    clients))
