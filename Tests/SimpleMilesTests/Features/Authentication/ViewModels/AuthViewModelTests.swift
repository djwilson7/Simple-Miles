import XCTest
@testable import SimpleMiles

// Unit tests for the AuthViewModel
final class AuthViewModelTests: XCTestCase {
    
    // The ViewModel under test
    var viewModel: AuthViewModel<MockAuthService>!
    
    // The mock service that simulates FirebaseAuth behavior
    var mockService: MockAuthService!

    // Called before each test method; initializes the mock service and view model
    override func setUp() {
        super.setUp()
        mockService = MockAuthService() // Reset mock between tests
        viewModel = AuthViewModel(authService: mockService) // Inject mock into view model
    }

    // Test that a successful login updates state as expected
    func testSuccessfulLogin() {
        mockService.shouldSucceed = true // Simulate successful login
        
        viewModel.email = "test@test.com" // Provide mock credentials
        viewModel.password = "test123"

        // Define expectation for asynchronous login process
        let expectation = XCTestExpectation(description: "Login completes")

        // Trigger login
        viewModel.loginWithEmail(viewModel.email, viewModel.password)

        // Delay to allow async closure to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Expect a success message
            XCTAssertEqual(self.viewModel.statusMessage, "Logged In")
            
            // Expect the error flag to be false
            XCTAssertFalse(self.viewModel.isStatusError)
            
            // Fulfill the expectation to conclude test
            expectation.fulfill()
        }

        // Allow up to 1 second for async operation to complete
        wait(for: [expectation], timeout: 1.0)
    }

    // Test that a failed login properly reflects an error state
    func testFailedLogin() {
        mockService.shouldSucceed = false // Simulate failed login
        
        viewModel.email = "test@test.com" // Provide mock credentials
        viewModel.password = "wrongpass"

        // Define expectation for asynchronous login process
        let expectation = XCTestExpectation(description: "Login fails")

        // Trigger login
        viewModel.loginWithEmail(viewModel.email, viewModel.password)

        // Delay to allow async closure to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Expect an error message containing "Login Error"
            XCTAssertTrue(self.viewModel.statusMessage?.contains("Login Error") ?? false)
            
            // Expect the error flag to be true
            XCTAssertTrue(self.viewModel.isStatusError)
            
            // Fulfill the expectation to conclude test
            expectation.fulfill()
        }

        // Allow up to 1 second for async operation to complete
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testEmptyEmailTriggersValidationError() {
        viewModel.email = ""                         // Empty email
        viewModel.password = "test123"          // Valid password

        viewModel.authenticateEmail()

        XCTAssertEqual(viewModel.statusMessage, "Email cannot be empty.")
        XCTAssertTrue(viewModel.isStatusError)
    }

    func testEmptyPasswordTriggersValidationError() {
        viewModel.email = "test@domain.com"          // Valid email
        viewModel.password = ""                      // Empty password

        viewModel.authenticateEmail()

        XCTAssertEqual(viewModel.statusMessage, "Password cannot be empty.")
        XCTAssertTrue(viewModel.isStatusError)
    }

    func testInvalidEmailFormatTriggersValidationError() {
        viewModel.email = "invalidemail@.com"
        viewModel.password = "password123"
        
        viewModel.authenticateEmail()
        
        XCTAssertEqual(viewModel.statusMessage, "Invalid Email Entered")
        XCTAssertTrue(viewModel.isStatusError)
    }

    func testValidEmailAndPasswordCallsLoginOrSignup() {
        // Setup
        viewModel.isLogin = true
        viewModel.email = "test@test.com"
        viewModel.password = "password123"
        mockService.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Auth call completes")
        
        viewModel.authenticateEmail()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.statusMessage, "Logged In")
            XCTAssertFalse(self.viewModel.isStatusError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

}
