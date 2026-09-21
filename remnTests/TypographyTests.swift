import Testing
@testable import remn

@MainActor
struct TypographyTests {
    @Test func bundledDisplayFontIsRegistered() {
        #expect(RemnTypography.isDisplayFontAvailable)
    }
}
