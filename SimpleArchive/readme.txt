======================================================== 찜찜 ========================================================



앱 내에서 사용되는 상수들을 한곳으로 모아서 static으로 사용해야 한다.
 
input, output enum의 case들 이름 교정
각 함수들 함수이름과 매개변수 이름들 그냥 index인거도 많으니까 바꿔준다.

이름 또는 컴포넌트 높이 바꾸고 결과를 보고서 titleLabel.text = newName등을 해주는게 나을까?
그러면 성공실패 여부 또는 에러만을 받기좋은 퍼블리셔가 뭘까. -> Result<Value,Error>

pageCreator, DirectoryCreator design pattern 괜찮은가

MemoDirectoryCoreDataRepositoryTests에서
test_fetchSystemDirectoryEntities_onFirstAppLaunch와
test_fetchSystemDirectoryEntities_successfully는 테스트 외부 환경과 약간의 관계가 있음.
프로덕트 코드 부분에서 생성하는 systemDirectory들과 관계가 있다.
또한 테스트 실행순서에 따라 두 테스트 함수가 약간의 관계를 가진다.

test_createStorageItem_withDirectory와 test_createStorageItem_withPage의 given stub데이터에서
최상위 디렉터리가 mainDirectory와 부모자식관계로 연결되어있지 않다.
코어데이터 엔티티 부분에서는 coreDataStack.setupEntitiesWithModels()함수를 통해 연결해주어서 테스트에 문제는없지만.
test_moveFileToDormantBox 테스트 함수들도 역시 그렇다.

테스트 외부에 랜덤적인 요소가 없게하자.
항상 같은값을 넣고 같은 값을 뱉게한다.
항상 정해진 답만을 출력하게한다.
UUID도 바꿨다.

강제 언래핑시 !보다 XCTUnwrap()활용 차이는 언래핑 실패시 테스트 실패로 간주된다.

helper 테스트, model들 테스트, 메서드가 몇개 없어서 안한 레포지토리, 뷰모델 테스트 해야한다.
UI Test도 하다가 말았다.

컬럼 에디트 팝업 뷰에서 이름 길어지면 위에 튀어나오는거 고쳐라
에디팅중인 컬럼을 드래그해서 순서바꿧을때 에디팅 두개 되는 버그.
컬럼들 컬렉션 뷰를 페이징으로 바꿀까.

ui에서 사용되는 여러 상수들을 선언해놓고 그 값만 바꿔주면 알아서 전체다바뀌게 편하게 할수는 없을까.


======================================================== 미구현 기능들 ========================================================

다이어그램 및 테스트
이미지, 테이블 컴포넌트도 추가하기

fixed에서는 정보보기, 이름변경, 삭제, 정렬 가 안된다.


============================================================================================================================

모든 디렉터리와 페이지는 parent:MemoDirectoryModel? 를 가지고있다.

이건 루트의 경우에만 없는건데 사실.. 이거 자주쓰는건데 계속 언래핑을 해줘야한다.

차라리 그 3개의 시스템 디렉터리를 다른 클래스로 좀 만드는게 좋지 않았을까 싶다.
