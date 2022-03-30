{
    "vrmjobshelp": {
        "title": "Limiting Concurrent Running Jobs",
        "message": "By default, VRM will run as many jobs concurrently as possible (after evaluating any dependencies). This means, it is possible for VRM to launch a large number of jobs at one time. In certain cases, this could be undesirable, for example, if you have a limit on the number of jobs any one user is allowed to submit at once, or if you are running on a local machine. In these types of instances, it may be desireable to limit the number of concurrently running jobs.<br/>The value entered here, will be used to limit those concurrently running processes. Any integer value is accepted, however, if the limit is less than or equal to 0, no limit will be imposed."
    },
    "gridhelp": {
        "gridtypehelp": {
            "title": "Selecting a Grid Type",
            "message": "VRM has the ability to run jobs either on the local machine, or on a grid system. In order for VRM to run grid jobs, you need to specify which grid software you use.<br/>VRM can be made to run with any grid system, and natively supports the following grid systems:<br/><br/><ul><li>Platform LSF</li><li>Sun Grid Engine (SGE)</li><li>Univa Grid Engine (UGE)</li><li>NetworkComputer (RTDA)</li></ul>"
        },
        "queuetimeouthelp": {
            "title": "Specifying Job Queue Timeouts",
            "message": "Once VRM launches a job to the grid, it will begin monitoring the time taken for that job to begin execution on the grid. By default, if the job does not start within 60 seconds, the queue timeout will kick in, VRM will kill the job, and relaunch it to the grid. You can modify this timeout value to be either longer or shorter depending on your environment, by specifying the amount of time (in seconds) VRM should wait before a queue timeout will occur."
        },
        "maxrunninghelp": {
            "title": "Limiting Concurrent Grid Jobs",
            "message": "By default, VRM will run as many jobs on the grid as possible (after evaluating dependencies), up to the maximum concurrent jobs specified in the \"General\" settings section. In certain cases, this could be undesireable,for example, if you have a limit on the number of jobs any one user is allowed to submit at once. In this case, you can limit the number of concurrently running grid jobs by entering that value here. Any integer value is accepted, however, if the limit is less than or equal to 0, no limit will be imposed."
        },
        "gripoptshelp": {
            "title": "Specifying Additional Grid Options",
            "message": "The basic command needed to submit the job to the specified grid is natively understood by VRM. However, you may want to include some additional options on your submit command to limit resources, or select a specific machine architecture type. In those instances, additional switches can be placed here which will be included in the grid submission command for all jobs."
        },
        "queueshelp": {
            "title": "Managing Grid Queues",
            "message": "VRM also supports the ability to launch different types of jobs to different grid queues. For example, you may submit compilation and simulation jobs to different queues. Here you can specify all the queue names which you wish to use in your regressions, and they will then be available for selection on the specific job pages of your regressions."
        }
    },
    "mailserverhelp": {
        "title": "Configuring Your Email Server",
        "message": "VRM will attempt to locate a local SMTP server on the machine from which it was launched, to use for sending status emails to users. If the machine you are running on either does not have an SMTP server available, or you would like to force VRM to use a specific server, you can specify that server here."
    }
}
