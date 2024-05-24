import java.util.ArrayList;
import processing.core.PVector;
import processing.sound.*;
import processing.core.PGraphics;

class Point {
    PVector pos;
    PVector vel;
    float alpha;
    ArrayList<Integer> connections;
    int createdAt;

    Point(PVector pos) {
        this.pos = pos;
        this.vel = PVector.random2D().mult(0.5);
        this.alpha = 255;
        this.connections = new ArrayList<Integer>();
        this.createdAt = frameCount;
    }
}

ArrayList<Point> points = new ArrayList<Point>();
String typedText = "";
float textX, textY;
int resetCount = 0;
boolean isNewWord = true;
boolean showStartMessage = true;

SinOsc sinOsc;
int fadeOutStartTime = 0;
Reverb reverb;

PGraphics pg; // 추가 캔버스

void setup() {
    size(1480, 720); // 메인 캔버스 크기 1600x720
    background(255);
    fill(255, 0, 0);
    textSize(25);

    sinOsc = new SinOsc(this);
    reverb = new Reverb(this);
    reverb.process(sinOsc);
    reverb.room(0.8);
    reverb.damp(0.1);
    reverb.wet(1.0);

    pg = createGraphics(200, 720); // 추가 캔버스 생성
}

void draw() {
    background(255, 60);
    
        if (showStartMessage) { // 시작 메시지 표시 여부 확인
        fill(0); // 검정색 텍스트
        textSize(30);
        textAlign(CENTER, CENTER);
        text("Type anything.\nTo start over from the beginning, press Enter", (width+200) / 2, height / 2);
    } else
       if (resetCount >= 5) {
        for (Point p : points) {
            for (Point other : points) {
                if (p != other) {
                    PVector dir = PVector.sub(other.pos, p.pos);
                    float d = dir.mag();
                    if (d > 0) {
                        dir.normalize();
                        float force = 0.1 * (1 / (d * d));
                        dir.mult(force);
                        p.vel.add(dir);
                    }
                }
            }

            // 벽 충돌 처리 (위치 업데이트 전에 확인)
            if (p.pos.x + p.vel.x < 207.5 || p.pos.x + p.vel.x > 1272.5) { // 좌우 경계 조정
                p.vel.x *= -1;
            }
            if (p.pos.y + p.vel.y < 7.5 || p.pos.y + p.vel.y > height - 7.5) {
                p.vel.y *= -1;
            }

            p.pos.add(p.vel); // 속도를 적용하여 점의 위치 업데이트

            if (frameCount - p.createdAt > 60) {
                p.alpha = max(0, p.alpha - 1);
            }
        }
    }


    // 점과 선 그리기 (메인 캔버스에 먼저 그림)
    for (Point p : points) {
        stroke(0, p.alpha);
        strokeWeight(1);
        for (int otherIndex : p.connections) {
            Point other = points.get(otherIndex);
            line(p.pos.x + 200, p.pos.y, other.pos.x + 200, other.pos.y);
            fill(0, p.alpha);
            ellipse(other.pos.x + 200, other.pos.y, 7.5, 7.5);
        }
        fill(0, p.alpha);
        ellipse(p.pos.x + 200, p.pos.y, 7.5, 7.5);
    }

    // 텍스트 표시 (메인 캔버스에 그림)
    fill(255, 0, 0);
    float textWidth = textWidth(typedText);
    textX = constrain(textX, 200 + textWidth/2 , width - textWidth); // 200만큼 이동
    textY = constrain(textY, 25, height - 25);
    text(typedText, textX, textY); // 텍스트 출력

    // 페이드 아웃 (이전과 동일)
    if (millis() - fadeOutStartTime <= 100 && fadeOutStartTime != 0) {
      float fadeAmount = (millis() - fadeOutStartTime) / 100.0;
      sinOsc.amp(0.5 * (1 - fadeAmount)); // 점진적으로 진폭 감소
    } else {
      sinOsc.stop(); // 페이드 아웃 완료 후 SinOsc 정지
      fadeOutStartTime = 0; // 페이드 아웃 시작 시간 초기화
    }


    pg.beginDraw();
    pg.background(0); // 추가 캔버스 배경 초기화
    pg.fill(255);
    pg.textSize(15);
    for (Point p : points) {
        pg.text("(" + p.pos.x + ", " + p.pos.y + ")", 10, 20 + points.indexOf(p) * 15);
    }
    pg.endDraw();
    image(pg, 0, 0); // 추가 캔버스를 (0, 0) 위치에 표시
}


// 키 입력 처리 함수
void keyPressed() {
  // Shift 또는 Caps Lock 키 입력 무시
  
  if (keyCode == SHIFT || (keyCode == CODED && keyEvent.getKeyCode() == java.awt.event.KeyEvent.VK_CAPS_LOCK)) {
    return;
  }
  
    showStartMessage = false;

  // 엔터 키 입력 시 텍스트, 점, 선 초기화
  if (key == ENTER || key == RETURN) {
    typedText = "";
    textX = random(width); 
    textY = random(height);
    points.clear(); // 점 리스트 초기화
    resetCount = 0; // 초기화 횟수 초기화
    isNewWord = true; // 새로운 단어 입력 상태로 변경
    showStartMessage = true; // 시작 메시지 다시 표시
  } 
  // 스페이스 바 또는 지우기(Backspace) 키 입력 시 텍스트 초기화 및 위치 변경, 초기화 횟수 증가
  else if (key == ' ' || keyCode == BACKSPACE) {
    typedText = "";
    textX = random(width); 
    textY = random(height);
    resetCount++; // 초기화 횟수 증가
    isNewWord = true; // 새로운 단어 입력 상태로 변경
  } 
  // 다른 키 입력 시 텍스트에 추가하고 새로운 점 생성
  else {
        showStartMessage = false; // 다른 키 입력 시 시작 메시지 사라짐
        typedText += key;

    // 새로운 단어 입력 시에만 소리 재생 및 페이드 아웃 시작
    if (isNewWord) {
      // 텍스트 위치에 따라 주파수 계산 (500 ~ 1000Hz 범위)
      float freq = map(textX, 0, width, 500, 1000);
      sinOsc.freq(freq); // 주파수 설정

      sinOsc.play(); // SinOsc 재생
      fadeOutStartTime = millis(); // 페이드 아웃 시작 시간 설정
      isNewWord = false; // 새로운 단어 입력 상태 해제
    }

    // 페이드 아웃 시작 후 100ms 동안 진폭을 0으로 감소
    if (millis() - fadeOutStartTime <= 100 && fadeOutStartTime != 0) {
      float fadeAmount = (millis() - fadeOutStartTime) / 100.0;
      sinOsc.amp(0.5 * (1 - fadeAmount)); // 점진적으로 진폭 감소
    } else {
      sinOsc.stop(); // 페이드 아웃 완료 후 SinOsc 정지
      fadeOutStartTime = 0; // 페이드 아웃 시작 시간 초기화
    }

    // 새로운 점 생성 및 초기화
    float x = random(15, 1280 - 15); // 캔버스 범위 안에서 랜덤한 x 좌표 생성
    float y = random(15, height - 15); // 캔버스 범위 안에서 랜덤한 y 좌표 생성
    Point newPoint = new Point(new PVector(x, y));

    // 기존 점들과 랜덤하게 연결
    if (points.size() > 1) {
      for (int i = 0; i < 3; i++) {
        int randomIndex = (int) random(points.size() - 1); // 연결할 점의 인덱스를 랜덤하게 선택
        newPoint.connections.add(randomIndex); // 새로운 점에 연결 정보 추가
        points.get(randomIndex).connections.add(points.size()); // 연결된 점에도 연결 정보 추가
      }
    }

    points.add(newPoint); // 새로운 점을 점 리스트에 추가
  }
}
