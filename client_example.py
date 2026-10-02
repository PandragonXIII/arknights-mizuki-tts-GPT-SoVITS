#!/usr/bin/env python3
"""水月 TTS 调用示例（无第三方依赖）

用法:
  python client_example.py "ドクター、おはようございます。" out.wav
  python client_example.py --ref ref_low "わかった。それなら、僕がやるよ。" out.wav
"""
import argparse
import json
import urllib.request
import os

SERVER = os.environ.get('TTS_SERVER', 'http://127.0.0.1:9880')

REF_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'refs')

REF_TEXTS = {
    'ref_high': 'さあ、悪人の数を減らせたね。全部ドクターのおかげだよ。',
    'ref_low': 'ケルシー先生が言ってたよ。ドクターが僕をそばに置くようになったら、それは僕を守ることを決めたんだって。',
    'ref_happy': '認められたの？これからはドクターともっといろんな場所に行って悪人を片付けていいってこと？',
    'ref_sad': 'あの時もこんな雨の日だったなぁ。予想外の贈り物を受け取って僕は変わったんだ。',
    'ref_surprise': 'え？ドクター、何人か逃してるよ。僕が代わりに片付けてくるね。',
    'ref_neutral': 'みんなの撤退を援護するなら手はあるよ。いや、援護するだけじゃダメだ。ここで悪人を全員始末しながら。',
}


def tts(text, out_path, ref_name='ref_high', lang='ja'):
    payload = {
        'text': text,
        'text_lang': lang,
        'ref_audio_path': os.path.join(REF_DIR, f'{ref_name}.wav'),
        'prompt_text': REF_TEXTS[ref_name],
        'prompt_lang': 'ja',
        'text_split_method': 'cut0',
        'streaming_mode': False,
    }
    req = urllib.request.Request(
        f'{SERVER}/tts',
        data=json.dumps(payload).encode(),
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        data = resp.read()
    with open(out_path, 'wb') as f:
        f.write(data)
    print(f'saved {out_path} ({len(data)} bytes)')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('text')
    parser.add_argument('output', nargs='?', default='output.wav')
    parser.add_argument('--ref', default='ref_high', choices=sorted(REF_TEXTS))
    parser.add_argument('--lang', default='ja', choices=['ja', 'zh'])
    args = parser.parse_args()
    tts(args.text, args.output, args.ref, args.lang)
