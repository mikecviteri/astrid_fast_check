#!/usr/local/bin/python3

import pandas as pd
import os
import wave
import contextlib
import re

pattern = re.compile(r'^\d+:\d+:\d+$')


class bcolors:
  HEADER = '\033[95m'
  OKBLUE = '\033[94m'
  OKCYAN = '\033[96m'
  OKGREEN = '\033[92m'
  WARNING = '\033[93m'
  FAIL = '\033[91m'
  ENDC = '\033[0m'
  BOLD = '\033[1m'
  UNDERLINE = '\033[4m'


def instructions():
  instructions = f'\n{bcolors.HEADER}INSTRUCCIONES:{bcolors.ENDC}\n\n\t{bcolors.OKBLUE}1. Descarga el archivo de Drive\
con las correcciones marcadas como .csv y ten lista la direccón completa de dónde se guardó el\
arcihvo\n\t2. Copia la carpeta con los audios .wav de Master/Remaster (carpeta Bounced Files)\
o última entrega antes de estas correcciones\n{bcolors.ENDC}'
  print(instructions)


def get_csv():
  path = input('Ingresa el archivo .csv')
  if os.path.exists(path) and path.endswith('.csv'):
    return path
  else:
    print(bcolors.FAIL + f'\n{path} No es un archivo .csv valido!\n' + bcolors.ENDC)
    get_full_time()


def read_csv(file):
  return pd.read_csv(file).astype(str)


def get_path(folder):
  if os.path.isdir(folder):
    return folder
  else:
    print(bcolors.FAIL + f'\n{folder} No es una carpeta valida!\n' + bcolors.ENDC)
    get_audio_duration()


def get_content(df, cols):
  rows = [i for i in range(len(df['Unnamed: {}'.format(cols['TCR'])])) if
          re.match(pattern, df['Unnamed: {}'.format(cols['TCR'])][i])]
  return (min(rows), max(rows))


def get_sec(time_str):
  """Get seconds from time."""
  h, m, s = time_str.split(':')
  return int(h) * 3600 + int(m) * 60 + int(s)


def to_hms(seconds):
  min, sec = divmod(seconds, 60)
  hour, min = divmod(min, 60)
  return "%02d:%02d:%02d" % (hour, min, sec)


def get_audio_duration():
  directory = get_path(input('Ingresa la carpeta en donde están todos los audios'))
  audios = sorted([i for i in os.listdir(directory) if i.endswith('.wav')], key=lambda x: x[-7:-4])
  result = list()
  for i in audios:
    with contextlib.closing(wave.open('{}/{}'.format(directory, i), 'r')) as f:
      frames = f.getnframes()
      rate = f.getframerate()
      duration = int(frames / float(rate))
      result.append(duration)
  return result


def get_full_time():
  full_csv_path = get_csv()
  file_name = os.path.basename(full_csv_path)
  df = read_csv(full_csv_path)

  my_dict = {}

  for col in range(0, 10):
    for row in range(0, 15):
      if df.iloc[row, col] == 'ESTADO':
        my_dict['Parts'] = col
      elif df.iloc[row, col] == 'TCR HH:MM:SS':
        my_dict['TCR'] = col
      else:
        pass

  first, last = get_content(df, my_dict)
  chapters_idx = [idx for idx, val in enumerate(df['Unnamed: {}'.format(my_dict['Parts'])][first:last + 1]) if
                  val == '-']
  tcr = []
  errors = []

  for i in range(first, last + 1):
    if re.match(pattern, df['Unnamed: {}'.format(my_dict['TCR'])][i]):
      tcr.append(get_sec(df['Unnamed: {}'.format(my_dict['TCR'])][i]))
    else:
      errors.append(i + 2)

  if len(errors) > 0:
    for i in range(len(errors)):
      pass
      print(bcolors.FAIL + f'Hay un ERROR en la fila {errors[i]}!' + bcolors.ENDC)
    exit()
  else:
    pass

  audio_lengths = get_audio_duration()
  count = 0

  output_list = []

  for i in range(len(tcr)):
    if i in chapters_idx:
      output_list.append([i + 1, f'FIN P{"{:03d}".format(count + 1)}', to_hms(sum(audio_lengths[:count + 1]))])
      count += 1
    else:
      output_list.append([i + 1, 'Error {}'.format(i + 1 - count), to_hms(tcr[i] + sum(audio_lengths[:count]))])

  conflict_times = []

  for i in range(len(output_list) - 1):
    if not output_list[i][2] <= (output_list[i + 1][2]):
      conflict_times.append([output_list[i][1], output_list[i + 1][1]])
    else:
      pass

  if len(conflict_times) > 0:
    for conflict in conflict_times:
      pass
      print(
        bcolors.FAIL + f'El {conflict[0].lower()} tiene un conflicto de tiempo con el {conflict[1].lower()}' + bcolors.ENDC)
    exit()
  else:
    pass

  pd.DataFrame(output_list, columns=['No.', 'Name', 'TCR']).to_csv(
    '{} (FAST CHECK).csv'.format(os.path.expanduser('~/Desktop/') + file_name[:-4]), index=False)


if __name__ == '__main__':
  instructions()
  get_full_time()
  print(bcolors.OKGREEN + '\nProceso terminado!\nBusca el csv final en tu escritorio\n' + bcolors.ENDC)
