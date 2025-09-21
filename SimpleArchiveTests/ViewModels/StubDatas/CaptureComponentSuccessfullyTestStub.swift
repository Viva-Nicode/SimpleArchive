import Foundation

@testable import SimpleArchive

final class CaptureComponentSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = NoUsed
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed
    
    let testTargetName = "test_captureComponent_successfully()"
    
    private var provideState: TestDataProvideState = .givenStubData
    
    func getStubData() -> Any {
        switch provideState {
            
        default:
            return ()
        }
    }
}

