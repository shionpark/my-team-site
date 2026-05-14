#!/bin/bash
VAULT="/Users/intalk/github/intalk-vault"
SITE="/Users/intalk/github/my-team-site"
CONTENT="$SITE/src/content"
IMAGES="$SITE/public/images"

# 첨부파일 정리: 미션 폴더의 이미지/영상을 93_attachments/로 이동
mkdir -p "$VAULT/_attachments"
find "$VAULT/00_missions/" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" -o -name "*.mp4" \) 2>/dev/null | while read f; do
  name=$(basename "$f")
  if [ ! -f "$VAULT/93_attachments/$name" ]; then
    mv "$f" "$VAULT/93_attachments/$name"
    echo "  이동: $name → 93_attachments/"
  else
    rm "$f"
    echo "  중복 삭제: $name (이미 _attachments에 존재)"
  fi
done

mkdir -p "$CONTENT/gallery" "$CONTENT/skills" "$CONTENT/analysis" "$CONTENT/proposals" "$CONTENT/missions"
mkdir -p "$IMAGES"

# 동기화 전 기존 콘텐츠 정리 (이미지는 유지, md만 삭제)
# gallery는 어드민에서 관리하므로 정리 대상에서 제외
rm -f "$CONTENT/missions/"*.md "$CONTENT/skills/"*.md "$CONTENT/analysis/"*.md "$CONTENT/proposals/"*.md

# 이미지 복사: 파일명 공백→언더스코어로 변환하여 복사
copy_image() {
  local src="$1"
  local name=$(basename "$src" | tr ' ' '_')
  cp "$src" "$IMAGES/$name"
}

find "$VAULT" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) | while read f; do
  copy_image "$f"
done

find "$VAULT/00_missions/" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) | while read f; do
  copy_image "$f"
done

# _attachments 폴더 (이미지 + 영상)
find "$VAULT/93_attachments/" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" -o -name "*.mp4" \) 2>/dev/null | while read f; do
  copy_image "$f"
done

echo "이미지 동기화: $(find "$IMAGES" -type f | wc -l)개 파일"

# 미션 파일: Week_0N_ 패턴만, 이미지 경로 변환 (공백→언더스코어)
# 모든 미션 파일 (Week_0* + 보조 문서)
find "$VAULT/00_missions/" -name "*.md" -size +10c | while read f; do
  filename=$(basename "$f")
  # 1) ![[image.png]] → ![image](/aaa-archive/images/image.png)
  # 2) ![alt](path/image.png) → ![alt](/aaa-archive/images/image.png)
  # 3) 이미지 URL 내 공백을 언더스코어로 변환
  sed -E \
    -e 's/!\[:[^:]+:\]\(https:\/\/a\.slack-edge\.com[^)]+\)//g' \
    -e 's/!\[([^]]*)\]\(attachment:[^)]+\)//g' \
    -e 's/!\[\[([^]|]+)\|[0-9]+\]\]/![\1](\/images\/\1)/g' \
    -e 's/!\[\[([^]]+)\]\]/![\1](\/images\/\1)/g' \
    -e 's/!\[([^]]*)\]\(([^)]*\/)?([^)]+\.(png|jpg|jpeg|gif|webp|svg))\|[0-9]+\)/![\1](\/images\/\3)/g' \
    -e 's/!\[([^]]*)\]\(([^)]*\/)?([^)]+\.(png|jpg|jpeg|gif|webp|svg))\)/![\1](\/images\/\3)/g' \
    -e 's/!\[([^]]*)\]\(([^)]*\/)?([^)]+\.mp4)\)/<video src="\/images\/\3" controls style="max-width:100%;border-radius:8px;"><\/video>/g' \
    "$f" | perl -pe 's{(\(/images/|src="/images/)([^)"]+)([)"])}{my $p=$1; my $n=$2; my $e=$3; $n=~s/ /_/g; "$p$n$e"}ge' \
    | sed -E 's/\[\[([^]|]+)\]\]/[\1](\/missions\/\1\/)/g' \
    | sed -E 's/\[\[([^]|]+)\|([^]]+)\]\]/[\2](\/missions\/\1\/)/g' \
    > "$CONTENT/missions/$filename"
done

# 후처리: 존재하지 않는 이미지 참조 제거
for mf in "$CONTENT/missions/"*.md; do
  [ -f "$mf" ] || continue
  perl -i -pe '
    if (/!\[([^\]]*)\]\(\/images\/([^)]+)\)/) {
      my $img = $2;
      $img =~ s/%20/_/g;
      unless (-f "'"$IMAGES"'/" . $img) {
        s/!\[[^\]]*\]\(\/images\/[^)]+\)//g;
      }
    }
  ' "$mf"
done

find "$VAULT/01_gallery/" -name "*.md" -exec cp {} "$CONTENT/gallery/" \; 2>/dev/null
find "$VAULT/02_skill_insight/" -name "*.md" ! -name "README.md" -exec cp {} "$CONTENT/skills/" \; 2>/dev/null
find "$VAULT/90_analysis/weekly/" -name "*.md" -exec cp {} "$CONTENT/analysis/" \; 2>/dev/null
find "$VAULT/91_proposals/" -name "*.md" -exec cp {} "$CONTENT/proposals/" \; 2>/dev/null

# 회의록 복사 (미션 페이지 피드백 콜아웃용)
mkdir -p "$SITE/src/data/meetings"
find "$VAULT/01_meetings/" -name "Week_*_weekly.md" -exec cp {} "$SITE/src/data/meetings/" \; 2>/dev/null

echo "동기화 완료: $(find "$CONTENT" -name '*.md' | wc -l)개 파일"
