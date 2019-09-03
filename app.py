import os
import sys
import time
import random
import timeago
import subprocess
import pandas as pd

from flask import Flask, render_template, request, jsonify, redirect, abort
from werkzeug import secure_filename

app = Flask(__name__)


TASKS_BASE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tasks')

@app.route('/')
def homepage():
    return render_template('index.html')


@app.route('/newtask', methods = ['POST'])
def start_new_task():
   if request.method == 'POST':
        task_id = str(random.randint(100000000000, 199999999999))
        task_path = os.path.join(TASKS_BASE_PATH, task_id)
        os.mkdir(task_path)

        fasta = request.files['file']
        fasta.save(os.path.join(task_path, 'fasta.fa'))

        email = request.form['email']
        region = request.form['region']

        with open(os.path.join(task_path, 'email'), 'w') as f:
            f.write(email)

        subprocess.Popen([sys.executable, './process.py', task_path, task_id, region])

        return redirect('/task/' + str(task_id))


@app.route('/task/<int:task_id>')
def task_status(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))

    if (not os.path.exists(task_path)) or os.path.exists(os.path.join(task_path, "done")) or os.path.exists(os.path.join(task_path, "exit")):
        return redirect('/result/' + str(task_id))
    else:
        email = open(os.path.join(task_path, "email"), 'r').read()
        return render_template('processing.html', started_message=timeago.format(os.path.getctime(task_path), locale='en_US'), email=email)


@app.route('/result/<int:task_id>')
def show_task_result(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    
    data = {'exists': False}

    if os.path.exists(task_path):
        data['exists'] = True
        data['task_id'] = str(task_id)
        data['email'] = open(os.path.join(task_path, "email"), 'r').read()
        data['sample_names'] = open(os.path.join(task_path, "counts_table.txt"), 'r').readline().strip().split('\t')

        Clostridiales_path = os.path.join(task_path, "report_Clostridiales_predprob.txt")
        Bacteroidales_path = os.path.join(task_path, "report_Bacteroidales_predprob.txt")

        if os.path.exists(Clostridiales_path) and os.path.exists(Bacteroidales_path):
            data['successful'] = True
            data['region'] = open(os.path.join(task_path, "region"), 'r').read()

            data['Clostridiales'] = [line.strip().split('\t') for line in open(Clostridiales_path, 'r').readlines()]
            data['Bacteroidales'] = [line.strip().split('\t') for line in open(Bacteroidales_path, 'r').readlines()]
            data['animals'] = data['Bacteroidales'][0]
        else:
            data['successful'] = False

    return render_template('report.html', data=data)

@app.route('/bubbleplot_data/<int:task_id>/<sample>')
def return_bubbleplot_data(task_id, sample):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    bubbleplot = os.path.join(task_path, 'report_bubbleplot', '%s.csv' % sample)
    
    if os.path.exists(bubbleplot):
        csv = open(bubbleplot, 'r').read()
        return csv
    
    abort(404)


@app.route('/heatmap_data/<int:task_id>')
def return_heatmap_data(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    
    output = {}
    for target in ['Clostridiales', 'Bacteroidales']:
        heatmap_data = os.path.join(task_path, 'report_BrayCurtis_'+target+'.txt')
        df = pd.read_csv(pd.compat.StringIO("sample_name\t" + open(heatmap_data).read()), delimiter='\t')
        output[target] = df.melt(id_vars=['sample_name']).to_json(orient='records')
    
    return jsonify(output)

if __name__ == '__main__':
    app.run(debug=True)
