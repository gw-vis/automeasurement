import argparse
import datetime
import subprocess
import threading

from vis import get_dofs
import itertools
import os
os.environ['EPICS_CA_ADDR_LIST'] = '10.68.10.5'
import ezca as _ezca
ezca = _ezca.Ezca()
if not ezca.prefix=='K1:':
    ezca = _ezca.Ezca('K1:')
print(ezca.prefix)

prefix = '/kagra/Dropbox/Measurements/VIS'
templates_fmt = prefix + '/TEMPLATES/PLANT_{sus}_{stg}.xml'
outdir_fmt = prefix + '/PLANT/{sus}/{yyyy}/{mm}/'
outfile_fmt = outdir_fmt + 'PLANT_{sus}_{sts}_{stg}_{exc}_{dof}_{ref}.xml'

def are_same_sustype(suslist):
    pass

def get_template(sus,stg):
    return templates_fmt.format(sus=sus,stg=stg)

def get_outfile(**kwargs):
    ref = kwargs['ref']
    yyyy,mm = ref[:4],ref[4:6]
    os.makedirs(outdir_fmt.format(sus=kwargs['sus'],yyyy=yyyy,mm=mm),exist_ok=True)
    return outfile_fmt.format(yyyy=yyyy,mm=mm,**kwargs)

def get_grdstate(sus):
    return ezca['GRD-VIS_{sus}_STATE_S'.format(sus=sus)]

def get_excchannel(sus,stg,exc,dof):
    if stg=='GAS':
        stg = dof        
        dof = 'GAS'
    
    return 'K1:VIS-{sus}_{stg}_{exc}_{dof}_EXC'.format(sus=sus,stg=stg,
                                                       exc=exc,dof=dof)

def get_refnum():
    now = datetime.datetime.now()
    return now.strftime('%Y%m%d%H%M')

def run_plants(sus,stg,exc,ref):    
    sts = get_grdstate(sus)
    for dof in get_dofs(sus,stg):
        outfile = get_outfile(sus=sus,stg=stg,exc=exc,ref=ref,dof=dof,sts=sts)
        template = get_template(sus=sus,stg=stg)
        excchannel = get_excchannel(sus,stg,exc,dof)
        cmd = '/kagra/bin/run_plant.sh %s %s %s 1 0'%(template,outfile,excchannel)
        ret = subprocess.run(cmd,shell=True,check=True)
        #print(outfile.split('/')[-1])

def hoge(sus,stglist,exclist,reflist,**kwargs):
    
    
    for stg,exc,ref in itertools.product(stglist,exclist,reflist):
        run_plants(sus=sus,stg=stg,exc=exc,ref=ref)    
        
def get_stages(stglist):        
    return stglist
    
if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--sus',nargs='+')
    parser.add_argument('--stg',nargs='+')
    parser.add_argument('--exc',nargs='+')
    args = parser.parse_args()
    suslist = args.sus    
    stglist = get_stages(args.stg)
    exclist = args.exc
    reflist = [get_refnum()]

    t = []
    for sus in suslist:
        print(sus)
        _t = threading.Thread(target=hoge,
                              args=(sus,stglist,exclist,reflist),
                              kwargs={'run':True})
        _t.start()
        t += [_t]
                
    cmd = "run_plant.sh"
    args = [prefix + '/TEMPLATES/PLANT_SR2_GAS.xml',
            prefix + '/PLANT/SR2/2022/03/PLANT_SR2_SAFE_GAS_TEST_F0_202203141038.xml']
    debug = 0
    quick = 0
