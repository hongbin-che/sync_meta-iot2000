# coding=utf-8
import os
import sys
import subprocess
import datetime
import io

List_For_Branch = []
def get_branch_list(dir):
    git_info_path = dir + "/git_info.txt"
    os.chdir(dir)
    if os.path.exists(git_info_path):
        os.system("rm -f "+git_info_path)
    os.system("git ls-remote -h https://github.com/siemens/meta-iot2000.git > git_info.txt")
    if os.path.exists(git_info_path) :
        with  io.open(git_info_path,'r',encoding='utf-8') as f:
            for line in f.readlines():
                line = line.split('refs/heads/')[1].replace('jan/docker','').replace('jan/queue','').replace('\n','').replace('\r','').strip()
                if  line != "":
                    List_For_Branch.append(line)
        i = 1
        for branch in List_For_Branch:
            print("\n\n########################## Branch{0}:{1} #############################################".format(i,branch))
            branch_dir_name = branch.replace('/','_')
            i=i+1
            os.chdir(dir)
            if not os.path.exists(dir+"/"+branch_dir_name):
                print("#{0} folder not exist,now git clone it".format(branch))
                os.system(" git clone https://github.com/siemens/meta-iot2000.git $PWD/"+branch_dir_name+" -b "+branch)
            os.chdir(dir+"/"+branch_dir_name)
            status=do_command("git pull origin "+branch+"|awk -F \" \" '{print $1}'" )
            print ("#Branch status:{0}".format(status))
            name=branch_dir_name
            print("\n#Start Trigger build job.......")
            trigger_build(status,branch,name)
            print("############################################################################################")


def trigger_build(st,br,jname):
    if st == "Already":
        print("#Repository no update,no need trigger job build...")
    elif st == "Auto-merging":
        print ("#Repository has change reload the Repository {}".format(br))
        os.chdir(code_dir)
        os.system('rm -rf '+code_dir+"/"+jname)
        os.system("git clone https://github.com/siemens/meta-iot2000.git $PWD/"+jname+" -b "+br)
        os.system("cd "+ script_dir+" && ./Build_IOT2000.sh -s "+script_dir+" -w "+build_dir+" -b "+br+" -o "+IS_ARCHIVE_OSS+" -d "+date_format+" 2>&1 | tee "+build_dir+"/BuildLog_"+date_format+".log")
    else:
        print ("#Repository has been update...\n#The Build task is about to be triggered...")
        os.system("cd "+ script_dir+" && ./Build_IOT2000.sh -s "+script_dir+" -w "+build_dir+" -b "+br+" -o "+IS_ARCHIVE_OSS+" -d "+date_format+" 2>&1 | tee "+build_dir+"/BuildLog_"+date_format+".log")

        

# execute command
def do_command(cmd):
    print("Run Command: ", str(cmd))
    out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    result = out.communicate()[0].decode().strip()
    out.wait()
    print(result)
    return result
 

if __name__ == '__main__':
    # code_dir = "/workspace/code/IOT2000"
    code_dir = sys.argv[1]
    
    # script_dir = "/workspace/code/iot2050-cm/IOT2000_Build"
    script_dir = sys.argv[2]

    # build_dir = "/workspace/IOT2000"
    build_dir = sys.argv[3]

    # IS_ARCHIVE_OSS : archive OSS Flag , defaut is NO
    IS_ARCHIVE_OSS = sys.argv[4]

    date = datetime.datetime.now()
    date_format = date.strftime("%Y-%m%d%H")  
    print ("# Build Date:{0}".format(date_format))  
    
    get_branch_list(code_dir)
