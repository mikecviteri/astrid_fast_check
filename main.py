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


def get_csv():
  path = input('Ingresa el archivo .csv')
  if os.path.exists(path) and path.endswith('.csv'):
    return (pd.read_csv(path).astype(str), os.path.basename(path))
  else:
    print(bcolors.FAIL + f'\n{path} No es un archivo .csv válido!\n' + bcolors.ENDC)
    get_full_time()


def get_path(folder):
  if os.path.isdir(folder):
    return folder
  else:
    print(bcolors.FAIL + f'\n{folder} No es una carpeta válida!\n' + bcolors.ENDC)
    get_audio_duration()


def get_content(df):
  rows = [i for i in range(len(df['Unnamed: 5'])) if re.match(pattern, df['Unnamed: 5'][i])]
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
    with contextlib.closing(wave.open(f'{directory}/{i}', 'r')) as f:
      frames = f.getnframes()
      rate = f.getframerate()
      duration = int(frames / float(rate))
      result.append(duration)
  return result


def get_full_time():
  df, file_name = get_csv()
  first, last = get_content(df)
  chapters_idx = [idx for idx, val in enumerate(df['Unnamed: 1'][first:last + 1]) if val == '-']
  tcr = []
  errors = []

  for i in range(first, last + 1):
    if re.match(pattern, df['Unnamed: 5'][i]):
      tcr.append(get_sec(df['Unnamed: 5'][i]))
    else:
      errors.append(i+2)

  if len(errors) > 0:
    for i in range(len(errors)):
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

  pd.DataFrame(output_list, columns=['No.', 'Name', 'TCR']).to_csv(
    f'{os.path.expanduser("~/Desktop/") + file_name[:-4]} (FAST CHECK).csv', index=False)


if __name__ == '__main__':
  get_full_time()
