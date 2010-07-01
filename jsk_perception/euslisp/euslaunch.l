;; Euslisp Roslaunch wrapper

;; originally roslaunch/src/roslaunch/core.py

;; utility functions
(defun str+ (&rest args)
  (apply #'concatenate string args))

;; xml  := (tag attr node*)
;; tag  := atom
;; attr := (cons*) | nil
;; node := xml | atom | nil
(defun simple-list2xml (obj &key (newline "") (attrfmt " ~A=\"~A\""))
  (cond
   ((null obj) "")
   ((atom obj) (string obj))
   ((vectorp obj)
    (apply #'concatenate string
	   (flatten (coerce (map vector #'(lambda(x)(list (string x) " ")) obj) cons))))
   ((listp obj)
    (let ((tag (car obj)) tagstr
	  (attrs (cadr obj)) attrstr
	  (nodes (cddr obj)) nodestr)
      (cond
       ((and (atom tag) (not (null tag)))
	(setq tagstr (string tag))
	(setq attrstr
	      (mapcar #'(lambda(a)
			  (format nil attrfmt (string (car a))
				  (string (if (atom (cdr a)) (cdr a) (cadr a)))))
		      attrs))
	(setq nodestr (mapcar #'(lambda(n)
				  (simple-list2xml n :newline newline
						   :attrfmt attrfmt))
			      nodes))
	(setq attrstr (apply #'concatenate string attrstr))
	(setq nodestr (apply #'concatenate string nodestr))
        (if nodes
            (str+ "<" tagstr attrstr ">" nodestr "</" tagstr ">" newline)
          (str+ "<" tagstr attrstr "/>" newline)))
       (t "")
       ))))
  )


(defclass rosparam
  :super propertied-object
  :slots (name value))
(defmethod rosparam
  (:init (&key ((:name _name) "") ((:value _value) ""))
    (setq name _name
	  value (string _value)))
  (:list ()
	 (list "param"
	       (list (cons "name" name)
		     (cons "value" value)))))

(defclass machine
  :super propertied-object
  :slots (name ros_root ros_package_path ros_ip address
	  ssh_port user password assignable env_args timeout))



(defclass rosnode
  :super propertied-object
  :slots (package type name namespace machine_name
	  args respawn remap_args env_args process_name
	  output cwd launch_prefix required filename params))
(defmethod rosnode
  (:init (_package _node_type &key ((:name _name) "")
		   ((:namespace _namespace) "/")
		   ((:machine_name _machine_name) nil)
		   ((:args _args) "") ((:respawn _respawn) nil)
		   ((:remap_args _remap_args) nil) ((:env_args _env_args) nil)
		   ((:output _output) "log") ((:cwd _cwd) "ROS_HOME")
		   ((:launch_prefix _launch_prefix) "")
		   ((:required _required) nil)
		   ((:filename _filename) "<unknown>"))
	 (setq package _package
	       type _node_type
	       name _name
	       namespace _namespace
	       machine_name _machine_name
	       args _args
	       respawn _respawn
	       remap_args _remap_args;
	       env_args _env_args;
;	       process_name _process_name
	       output _output
	       cwd _cwd
	       launch_prefix _launch_prefix
	       required _required
	       filename _filename))
  (:package (&rest arg) (setq package (or (car arg) package)))
  (:type (&rest arg) (setq type (or (car arg) type)))
  (:name (&rest arg) (setq name (or (car arg) name)))
  (:args (&rest arg) (setq args (or (car arg) args)))
  (:params (&rest arg) (setq params (or (car arg) params)))

  (:attrs ()
    (append
     (list (cons "pkg" package) (cons "type" type)
	   (cons "ns" namespace)(cons "args" args) (cons "output" output)
	   (cons "cwd" cwd) (cons "respawn" (if respawn "True" "False"))
	   (cons "name" name) (cons "launch-prefix" launch_prefix)
	   (cons "required" (if required "True" "False")))
     (if machine_name (list (cons "machine" machine_name)))))
  (:remap_args ()
    (mapcar #'(lambda(x)(list "remap"
			      (list (cons "from" (car x))
				    (cons "to"   (cdr x)))))
	    remap_args))
  (:env_args ()
    (mapcar #'(lambda(x)(list "env"
			      (list (cons "name"  (car x))
				    (cons "value" (cdr x)))))
	    env_args))
  (:list ()
    (list "node"
	  (send self :attrs)
	  (append nil (send self :remap_args) (send self :env_args)
		  (mapcar #'(lambda(x)(send x :list)) params))))
  )

(defun launch (nodes)
    (let (cmd)
      (setq cmd (format nil (str+
"python -c \""
"import roslib;roslib.load_manifest('roslaunch');"
"import rospy;import roslaunch;import roslaunch;import thread;import signal;~%"
"node_exit = False~%"
"class EusLaunch(roslaunch.parent.ROSLaunchParent):~%"
"    def __init__(self, run_id):~%"
"        roslaunch.parent.ROSLaunchParent.__init__(self, run_id, [])~%"
"    def _load_config(self):~%"
"        self.config = roslaunch.config.load_config_default([],None,['~A'])~%"
"def do_until_key ():~%"
"    dummy = raw_input()~%"
"    global node_exit~%"
"    node_exit = True~%"
"if __name__ == '__main__':~%"
"    rospy.init_node('euslaunch')~%"
"    signal.signal(signal.SIGINT, signal.SIG_IGN)~%"
"    roslaunch.rlutil._wait_for_master()~%"
"    uuid = roslaunch.rlutil.get_or_generate_uuid(None, True)~%"
"    roslaunch.configure_logging(uuid)~%"
"    p = EusLaunch(uuid)~%"
"    p.start()~%"
"    thread.start_new_thread(do_until_key,())~%"
"    while not node_exit:~%"
"        p.spin_once()~%\"")
	      (simple-list2xml (append (list "launch" nil)
				       (send-all nodes :list))
			       :attrfmt " ~A=\\\"~A\\\"")))
      (unix::piped-fork cmd)
      ))

(defun ros::rosnode-list ()
  (let ((pipe (piped-fork "rosnode" "list")) str lst)
    (while (setq str (read-line pipe nil nil))
      (push str lst))
    lst))

;(setq mynode (instance rosnode :init "tf" "static_transform_publisher" :args "1 0 0 0 0 0 0 /a /b 100"))
;(send mynode :params (list (instance rosparam :init :name "weight" :value "100")))
;(let ((pipe (launch (list mynode))))
;  (unix:sleep 10)
;  (format pipe "~%")) ;; SIGINT
