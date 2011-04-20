(load "package://jsk_maps/euslisp/eng2-map.l")
(load "models/elevator_call_panel_eng2-object.l")
(load "models/elevator_inside_panel_eng2-object.l")

(load "package://jsk_maps/src/plane-building-model.l")

(defun make-eng2-scene ()
  (let* ((map (make-eng2-map-map))
	 (scene
	  (instance
	   plane-building-model :init :name "/eng2"
	   :objects
	   (append
	    (list
	     map
	     (elevator_call_panel_eng2 :name "elevator_call_panel")
	     (elevator_inside_panel_eng2 :name "elevator_inside_panel")
	    ;; 2F
	    (make-cascoords :rot #2f((0.0 1.0 0.0) (-1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(3100.0 -31450.0 0.0)
			    :name "/eng2/2f/elevator_call_panel-front")
	    (make-cascoords :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
			    :pos #f(2100.0 -33500.0 0.0)
			    :name "/eng2/2f/elevator_inside_panel-front")
	    (make-cascoords :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(2000.0 -31000.0 0.0)
			    :name "/eng2/2f/elevator-outside")
	    ;; 7F
	    (make-cascoords :rot #2f((0.0 1.0 0.0) (-1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(63100.0 -31450.0 0.0)
			    :name "/eng2/7f/elevator_call_panel-front")
	    (make-cascoords :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
			    :pos #f(62100.0 -33500.0 0.0)
			    :name "/eng2/7f/elevator_inside_panel-front")
	    (make-cascoords :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(62000.0 -31000.0 0.0)
			    :name "/eng2/7f/elevator-outside")
	    (make-cascoords :rot #2f((-1.0 0.0 0.0) (0.0 -1.0 0.0) (0.0 0.0 1.0))
			    :pos #f(58850.0 6300.0 0.0)
			    :name "/eng2/7f/room73A3-front")
	    (make-cascoords :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(56750.0 4900.0 0.0)
			    :name "/eng2/7f/room73A3-base")
	    ;; 8F
	    (make-cascoords :rot #2f((0.0 1.0 0.0) (-1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(123100.0 -31450.0 0.0)
			    :name "/eng2/8f/elevator_call_panel-front")
	    (make-cascoords :rot #2f((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0))
			    :pos #f(122100.0 -33500.0 0.0)
			    :name "/eng2/8f/elevator_inside_panel-front")
	    (make-cascoords :rot #2f((0.0 -1.0 0.0) (1.0 0.0 0.0) (0.0 0.0 1.0))
			    :pos #f(122000.0 -31000.0 0.0)
			    :name "/eng2/8f/elevator-outside")
	    ;; object position
	    (make-cascoords :pos #f(3200.0 -31950 920) :rpy #f(1.5706 0 0)
			    :name "/eng2/2f/elevator_call_panel")
	    (make-cascoords :pos #f(2900 -33650 1000) :rpy #f(3.1416 0 0)
			    :name "/eng2/2f/elevator_inside_panel")
	    (make-cascoords :pos #f(63200 -31950 920) :rpy #f(1.5706 0 0)
			    :name "/eng2/7f/elevator_call_panel")
	    (make-cascoords :pos #f(62900 -33650 1000) :rpy #f(3.1416 0 0)
			    :name "/eng2/7f/elevator_inside_panel")
	    (make-cascoords :pos #f(123200 -31950 920) :rpy #f(1.5706 0 0)
			    :name "/eng2/8f/elevator_call_panel")
	    (make-cascoords :pos #f(122900 -33650 1000) :rpy #f(3.1416 0 0)
			    :name "/eng2/8f/elevator_inside_panel"))
	    (flatten (send map :descendants))
	    ))))
    ;; scene -> map
    (send scene :assoc map)
    (send scene :floors '("/eng2/2f" "/eng2/7f" "/eng2/8f")) ;; set floor information

    (dolist (obj (send scene :objects))
      ;; map -> unassoc obj
      (unless (find obj (flatten (send scene :inheritance)))
	(send map :assoc obj))
      ;; first charactor of obj-name must be slash
      (when (not (eq (char (send obj :name) 0) #\/))
	(send obj :name (format nil "/~A" (send obj :name)))))
    scene))

;; example
;; (load "package://pr2eus/pr2-interface")
;; (ros::roseus "eng8_navigation")
;; (defvar *tfl* (instance ros::transform-listener :init))
;; (setq *ri* (instance pr2-interface :init))
;; (objects (list (setq *eng8-scene*  (make-eng8-scene))))
;; (move-to (car (send *eng8-scene* :find-object "/eng8/6f/room602-front")))
;;
;; debug
#|
(defun move-to-test (&optional (spot "/eng8/6f/room602-base"))
  (load "eng8-map-scene.l")
  (objects (list (setq *eng8-scene*  (make-eng8-scene))))
  (send *irtviewer* :look-all (make-cube 1000 1000 10000))
  (send (car (send *eng8-scene* :find-object spot)) :draw-on :flush t :size 1000 :color #f(1 0 0))
  (move-to (car (send *eng8-scene* :find-object spot)))
  )
|#