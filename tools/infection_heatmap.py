import pynetlogo
import datetime
import random
import os

def instance_netlogo():
    netlogo = pynetlogo.NetLogoLink(
        gui=True,
        jvm_path=r"C:\Program Files\NetLogo 6.4.0\runtime\bin\server\jvm.dll",
    )

    netlogo.load_model(r"./model/infected_patch_test.nlogo")
    return netlogo

def test_path(path):
    if not os.path.exists(path):
        os.makedirs(path)


###
### here you specify the path to the infection heatmap data that is output by the write_inf_map function in the netlogo model.
### unlike the console_out_results, no additional steps are needed. this will create a root directory, then additional directories for each
### set of parameters, and then create images of the heat map within each parameter folder. normally behaviour space is set to 10
### repetitions so 10 images should be created per set of parameters. combined output is commented out at the bottom, as it
### is not working correctly at this moment, i will fix this whenever i have a moment. its combining all of the run data which
### seems to hang when sending it to netlogo. this needs to only combine the data within the same parameter set - FIX LATER
###


def prep_file(f = "./model/run1/run1_inf.txt" ):
    with open (f,"r") as f:
        lines = f.readlines()


    lines[0] = lines[0].replace("(","")
    lines[0] = lines[0].replace(")","")
    lines[0] = lines[0].replace('"','')
    a = lines[0].split("]")
    b = [x.strip().split('[') for x in a]

    for x in b:
        if x[0] == '':
            b.pop(b.index(x))

    x = b[0][0]
    res = ['total',' '.join(z[1] for z in b )]

    return b,res

def commands(name,patches,file):
    netlogo.command("setup")
    netlogo.command("set patch-list (list {})".format(patches))
    netlogo.command("set cutoff 5")
    netlogo.command("go")
    #netlogo.command("overlay")
    f_name = file + '.png'
    p = "./{}/{}".format('run1',name)
    test_path(p)
    p = "{}/{}".format(p,f_name)
    netlogo.command('export-view  "{}"'.format(p))

def commands_combined(name, patches):
    netlogo.command("setup")
    netlogo.command("set patch-list (list {})".format(patches))
    netlogo.command("set cutoff 100")
    netlogo.command("go")
    netlogo.command("overlay")
    f_name = name + '.png'
    netlogo.command('export-view  "{}"'.format(f_name))


run_list, combined = prep_file()
netlogo = instance_netlogo()



os.chdir("./model")
for x in run_list:
    timestamp = datetime.datetime.now().strftime("%d%b%Y_%H%M%S").upper()

    indx = run_list.index(x)
    fname = "{}_{}_{}".format(x[0] ,  timestamp,indx)
    commands(x[0],x[1],fname)


# timestamp = datetime.datetime.now().strftime("%d%b%Y_%H%M%S").upper()
# fname = "{}_combined_{}".format(combined[0],timestamp)
# commands_combined(fname,combined[1])



