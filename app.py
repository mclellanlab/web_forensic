import os
import io
import sys
import time
import random
import zipfile
import timeago
import subprocess
import pandas as pd

from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, abort, send_file
from werkzeug import secure_filename

app = Flask(__name__)


TASKS_BASE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tasks')

@app.route('/')
def homepage():
    return render_template('index.html')


@app.route('/faq')
def faq():
    return render_template('faq.html')    


@app.route('/classifier')
def classifier():
    return render_template('classifier.html')    


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


@app.route('/task/<task_id>')
def task_status(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))

    if (not os.path.exists(task_path)) or os.path.exists(os.path.join(task_path, "done")) or os.path.exists(os.path.join(task_path, "exit")):
        return redirect('/result/' + str(task_id))
    else:
        email = open(os.path.join(task_path, "email"), 'r').read()
        return render_template('processing.html', started_message=timeago.format(os.path.getctime(task_path), locale='en_US'), email=email, task_id=task_id)


@app.route('/result/<task_id>')
def show_task_result(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    
    data = {'exists': False}

    if os.path.exists(task_path):
        data['exists'] = True
        data['task_id'] = str(task_id)
        data['submitted_date'] = datetime.utcfromtimestamp(os.path.getctime(task_path)).strftime('%b %d, %Y')
        data['email'] = open(os.path.join(task_path, "email"), 'r').read()
        data['sample_names'] = open(os.path.join(task_path, "counts_table.txt"), 'r').readline().strip().split('\t')
        data['reads_per_sample'] = pd.read_csv(os.path.join(task_path, "reads_per_sample.txt"), sep='\t', index_col='sample_name').to_dict()['reads']

        for group in ['Clostridiales', 'Bacteroidales']:
            data[group + '_samples_sums'] = pd.read_csv(os.path.join(task_path, group + "_samples_sums.txt"), sep='\t', index_col='sample_name').to_dict()['sum']
            data[group + '_samples_unique_count'] = pd.read_csv(os.path.join(task_path, group + "_samples_unique_count.txt"), sep='\t', index_col='sample_name').to_dict()['unique_count']

        Clostridiales_path = os.path.join(task_path, "report_clostridiales_predprob.txt")
        Bacteroidales_path = os.path.join(task_path, "report_bacteroidales_predprob.txt")


        for table_name in ['classifier_type', 'cutoff_low', 'cutoff']:
            data[table_name] = {}
            for region in ['v4', 'v6']:
                data[table_name][region] = {}
                with open(os.path.join('static/data/Cutoff_Tables', table_name + "_" + region + ".txt"), "r") as table:
                    for line in table.readlines()[1:]:
                        classifier_, Clos_, Bacte_ = line.strip().split()
                        data[table_name][region][classifier_] = {
                            'Clostridiales': Clos_,
                            'Bacteroidales': Bacte_
                        }
        if os.path.exists(Clostridiales_path) and os.path.exists(Bacteroidales_path):
            data['successful'] = True
            data['region'] = open(os.path.join(task_path, "region"), 'r').read()

            data['Clostridiales'] = [line.strip().split('\t') for line in open(Clostridiales_path, 'r').readlines()]
            data['Bacteroidales'] = [line.strip().split('\t') for line in open(Bacteroidales_path, 'r').readlines()]
            data['animals'] = data['Bacteroidales'][0]
        else:
            data['successful'] = False

    return render_template('report.html', data=data)


@app.route('/result/<task_id>/download')
def download_result(task_id):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w') as zf:
        for root, dirs, files in os.walk(task_path):
            for file in files:
                zf.write(os.path.join(root, file), os.path.relpath(os.path.join(root, file), os.path.join(task_path, '..')))

    zip_buffer.seek(0)
    return send_file(zip_buffer, attachment_filename='forensic_%s.zip' % str(task_id), as_attachment=True)


@app.route('/bubbleplot_data/<task_id>/<sample>')
def return_bubbleplot_data(task_id, sample):
    task_path = os.path.join(TASKS_BASE_PATH, str(task_id))
    bubbleplot = os.path.join(task_path, 'report_bubbleplot', '%s.csv' % sample)
    
    if os.path.exists(bubbleplot):
        csv = open(bubbleplot, 'r').read()
        return csv
    
    abort(404)


@app.route('/heatmap_data/<task_id>')
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
