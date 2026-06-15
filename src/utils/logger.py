class Logger():
    """This is a custom logger component. It's supposed to be able to fit into any scenario, or at least to be expanded onto. 
    By default it saves its logs under ./logs, creating the folder if it doesn't exist.
    
    The default log filename is log-DD-MM-hh-mm-ss, which is a snapshot of when the log was created.
    Each entry inside the log follows the same format to identify when an action ocurred.
    """
    
    def __init__(self, folderpath : str | None = None):
        """Initializes the log

        Args:
            folderpath (str | None, optional): The folder where to store the logs. Defaults to ./logs.
        """
        import os
        from datetime import datetime

        if folderpath is None:
            folderpath = os.path.join(os.getcwd(), "logs")
            
        os.makedirs(folderpath, exist_ok=True)
        
        timestamp = datetime.now().strftime("%d-%m---%H-%M-%S")
        self.filepath = os.path.join(folderpath, f"log-{timestamp}.txt")    
        self.log_cleanup()
    
    def log_cleanup(self):
        """
        Cleans up old log files, keeping only the most recent 50 logs.
        """
        
        import os
        from glob import glob

        log_files = glob(os.path.join(os.path.dirname(self.filepath), "log-*.txt"))
        log_files.sort(key=os.path.getmtime, reverse=True)
        
        for old_log in log_files[50:]:
            os.remove(old_log)
    
    def log(self, message: str):
        from datetime import datetime

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[INFO] [{timestamp}] {message}\n"
        
        with open(self.filepath, "a") as log_file:
            log_file.write(log_entry)
            #Flush to ensure immediate write
            log_file.flush()
            
        
    def log_error(self, message: str):
        from datetime import datetime

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[ERROR] [{timestamp}] {message}\n"
        
        with open(self.filepath, "a") as log_file:
            log_file.write(log_entry)
            #Flush to ensure immediate write
            log_file.flush()
            
        
    def log_warning(self, message: str):
        from datetime import datetime

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[WARNING] [{timestamp}] {message}\n"
        
        with open(self.filepath, "a") as log_file:
            log_file.write(log_entry)
            #Flush to ensure immediate write
            log_file.flush()
            
            
            
    def get_log(self, filename):
        import os

        filepath = os.path.join(os.path.dirname(self.filepath), filename)
        if not os.path.isfile(filepath):
            raise FileNotFoundError(f"No log file found at {filepath}")
        
        with open(filepath, "r") as log_file:
            return log_file.read()
        