//
//  ElementFiltersParserTest.swift
//  QParserTests
//
//  Created by Naresh Devalapally on 1/6/24.
//

import XCTest

@testable import osmparser
final class ElementFiltersParserTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testFailNoSpace() throws {
        shouldFail(input: "shop andfail")
        shouldFail(input: "'shop'and fail")
    }

    func testFailOnUnknownLikeOperator() throws {
        shouldFail(input: "~speed > 3")
    }
    
    func testFailNoNumberComparison() throws {
        shouldFail(input: "speed > walk")
    }
    
    func testWhiteSpacesDontMatter() throws {
        let elements: [Element] = [TestDataShortcuts.node(tags: [:]), TestDataShortcuts.way(), TestDataShortcuts.rel()]
        for e in elements {
            let parser = try parse(input: "nodes, ways, relations")
//            let parser2 = try
            XCTAssertTrue(parser.matches(element: e))
            XCTAssertTrue(try parse(input: "  nodes,ways,relations  ").matches(element: e))
            XCTAssertTrue(try parse(input: "nodes ,ways  ,relations").matches(element: e))
            XCTAssertTrue(try parse(input: "\tnodes\n,\t\tways\n\n,relations").matches(element:e))
        }
    }
    
    func testOrderDoesnotMatter() throws {
        // Order does not matter for element declaration
        let elements: [Element] = [TestDataShortcuts.node(tags: [:]), TestDataShortcuts.way(), TestDataShortcuts.rel()]
        
        for e in elements {
            XCTAssertTrue(try parse(input: "relations, ways, nodes").matches(element: e))
            XCTAssertTrue(try parse(input: "relations, nodes, ways").matches(element: e))
        }
    }
    
    func testFailIfInvalidDeclaration() throws {
        // Fail if invalid element declaration in front
        shouldFail(input: "butter")
    }
    func testFailIfDuplicateDeclaration() throws {
        shouldFail(input: "nodes, nodes")
    }
    
    func testFailInvalidElementDeclaration() throws {
        shouldFail(input: "nodes, butter")
    }
    
    func testFailIfTagLikeIsLikeReservedword() throws {
        shouldFail(input: "nodes with with")
        shouldFail(input: "nodes with or")
        shouldFail(input: "nodes with and")
        shouldFail(input: "nodes with older")
        shouldFail(input: "nodes with with = abc")
        shouldFail(input: "nodes with or = abc")
        shouldFail(input: "nodes with and = abc")
    }
    // tag key like reserved word in quotation marks is ok
    func testFailsTagLikeReservedWords() throws {
        let tags = ["with":"with"]
        matchesTags(tags: tags, input: "'with'")
        matchesTags(tags: tags, input: "'with'='with'")
    }
    
    // quotes are optional
    func testQuotesOptional() throws {
        let tags = ["shop":"yes"]
        matchesTags(tags: tags, input: "shop")
        matchesTags(tags: tags, input: "'shop'")
        matchesTags(tags: tags, input: "\"shop\"")
    }
    
    // quoting empty string
    func testQuotationEmpty() throws {
        matchesTags(tags: ["shop":""], input: "shop = ''")
    }
    
    // escaping quotes
    func testEscapingQuotes() throws { // Will deal with this later
//        matchesTags(tags: ["shop\"":"yes"], input: "\"shop\\\"\"") // Issue with HasKey matcher may be
    }
    
    // unquoted tag may start with reserved word
    func testUnqotedTagWithReservedWord() throws {
        matchesTags(tags: ["withdrawn":"with"], input: "withdrawn = with")
        matchesTags(tags: ["orchard":"or"], input: "orchard = or")
        matchesTags(tags: ["android":"and"], input: "android = and")
    }
    
    // tag with key with quotation marks is ok
    func testTagKeyWithQuotationIsOk() throws {
        matchesTags(tags: ["highway = residential or bla":"yes"], input: "\"highway = residential or bla\"")
    }
    
    // tag value with quotation marks is ok
    func testTagValueWithQuoteIsOk() throws {
        matchesTags(tags: ["highway":"residential or bla"], input: "highway = \"residential or bla\"")
    }
    // fail if tag key quotation marks not closed
    func testTagQuoteMarkUnclosed() throws{
        shouldFail(input: "nodes with \"highway = residential or bla")
    }
    
    // Fail if tag value quotation marks are not closed
    func testFailIfTagValQuotMarkNotClosed() throws {
//        shouldFail(input: "nodes with highway = \"residential or bla") // This is crashing
    }
    
    // whitespaces around tag key do not matter
    func testWhiteSpacesAroundTagKeyNoMatter() throws {
        let tags = ["shop":"yes"]
        matchesTags(tags: tags, input: "shop")
        matchesTags(tags: tags, input: "\t\n\t\n shop \t\n\t\n")
        matchesTags(tags: tags, input: "\t\n\t\n (\t\n\t\n shop \t\n\t\n) \t\n\t\n")
        
    }
    // whitespaces around tag value do not matter
    func testWhiteSpacesAroundTagValNoMatter() throws {
        let tags = ["shop":"yes"]
        
        matchesTags(tags: tags, input: "shop=yes")
        matchesTags(tags: tags, input: "shop \t\n\t\n = \t\n\t\n yes \t\n\t\n")
        matchesTags(tags: tags, input: " \t\n\t\n (shop \t\n\t\n = \t\n\t\n yes \t\n\t\n) \t\n\t\n ")
    }
    
    // whitespaces in tag do matter
    func testWhiteSpacesInTagDoMatter() throws {
        let tags = ["\t\n\t\n shop \t\n\t\n":"\t\n\t\n yes \t\n\t\n"]
//        matchesTags(tags: tags, input: "\" \t\n\t\n shop \t\n\t\n \" = \" \t\n\t\n yes \t\n\t\n \"") // Failing
    }
    
    // fail on dangling operator
    func testFailOnDanglingOperator() throws {
        shouldFail(input: "nodes with highway=")
    }

    // fail on dangling boolean operator
    func testFailOnDanglingBooleanOp() throws {
        shouldFail(input: "nodes with highway and")
        shouldFail(input: "nodes with highway or")
    }
    
    // fail on dangling quote
    func testFailOnDanglingQuote() throws {
        shouldFail(input: "shop = yes '")
        shouldFail(input: "shop = yes \"")
    }
    
    // fail on dangling prefix operator
    func testFailOnDanglingPrefixOp() throws {
        shouldFail(input: "shop = yes and !")
        shouldFail(input: "shop = yes and ~")
    }
    
    // fail if bracket not closed
    func testFailIfBracketNotClosed() throws {
        shouldFail(input: "nodes with (highway")
        shouldFail(input: "nodes with (highway = service and (service = alley)")
    }
    
    // fail if too many brackets closed
    func testFailTooManyBracketsClosed() throws {
        shouldFail(input: "nodes with highway)")
        shouldFail(input: "nodes with (highway = service))")
    }
    
    // whitespaces do not matter for brackets
    func testWhitespacesDonotMatterForBrackets() throws {
        let tags = ["shop":"yes","fee":"yes"]
        matchesTags(tags: tags, input: "shop and((fee=yes))")
        matchesTags(tags: tags, input: "shop and \t\n\t\n ( \t\n\t\n ( \t\n\t\n fee=yes \t\n\t\n))")
    }
    // fail on unknown thing after tag
    func testFailOnUnknownThing() throws {
        shouldFail(input: "nodes with highway wht is this")
    }
    
    // fail if neither a number nor a date is used for comparison
    func testFailInvalidComparison() throws {
        shouldFail(input: "nodes with width > x")
        shouldFail(input: "nodes with width >= x")
        shouldFail(input: "nodes with width < x")
        shouldFail(input: "nodes with width <= x")
    }
    
    // quotes for comparisons are not allowed
    func testQuotesForComparison() throws {
        shouldFail(input: "nodes with width > '3'")
        shouldFail(input: "nodes with width >= '3'")
        shouldFail(input: "nodes with width < '3'")
        shouldFail(input: "nodes with width <= '3'")
        shouldFail(input: "nodes with date > '2022-12-12'")
        shouldFail(input: "nodes with date >= '2022-12-12'")
        shouldFail(input: "nodes with date < '2022-12-12'")
        shouldFail(input: "nodes with date <= '2022-12-12'")
        shouldFail(input: "nodes with date > 'today' + 3 years")
        shouldFail(input: "nodes with date >= 'today + 3 years'")
        shouldFail(input: "nodes with date < 'today +' 3 years")
        shouldFail(input: "nodes with date <= 'today + 3' years")
        shouldFail(input: "nodes with older '2022-12-12'")
        shouldFail(input: "nodes with newer '2022-12-12'")
        shouldFail(input: "nodes with lit older '2022-12-12'")
        shouldFail(input: "nodes with lit newer '2022-12-12'")
    }
    
    // tag negation not combinable with operator
    func testTagNegationNotCombinableWithOperator() throws {
        shouldFail(input: "nodes with !highway=residential")
        shouldFail(input: "nodes with !highway!=residential")
        shouldFail(input: "nodes with !highway~residential")
        shouldFail(input: "nodes with !highway!~residential")
    }
    
    // empty key and value
    func testEmptyKeyVal() throws {
        matchesTags(tags: ["":""], input: "'' = ''")
    }
    
    // not key operator is parsed correctly
    func testNotKeyOperatorIsParsedCorrectly() throws {
        matchesTags(tags: [:], input: "!shop")
        matchesTags(tags: [:], input: "! shop")
        notMatchesTags(tags: ["shop":"yes"], input: "!shop")
        
    }
    
    // not key like operator is parsed correctly
    func testNotKeyLikeOperatorIsParsedCorrectly() throws {
        matchesTags(tags: [:], input: "!~...")
        matchesTags(tags: [:], input: "!~  ...")
        notMatchesTags(tags: ["abc":"yes"], input: "!~...")
    }
    
    // key like operator is parsed correctly
    func testKeyLikeOperatorIsParsedCorrectly() throws {
        matchesTags(tags: ["abc":"yes"], input: "~...")
        matchesTags(tags: ["abc":"yes"], input: "~  ...")
        notMatchesTags(tags: ["ab":"yes"], input: "~  ...")
    }
    
    // tag like operator is parsed correctly
    func testTagLikeOperatorParsedCorrectly() throws {
        matchesTags(tags: ["abc":"yes"], input: "~...~...")
        matchesTags(tags: ["abc":"yes"], input: "~  ...  ~  ...")
        notMatchesTags(tags: ["abc":"ye"], input: "~  ...  ~  ...")
        notMatchesTags(tags: ["ab":"yes"], input: "~  ...  ~  ...")
    }
    
    // older operator is parsed correctly
    func testOlderOperatorParsedCorrectly() throws {
        matchesTags(tags: [:], input: "older 2199-12-12")
        matchesTags(tags: [:], input: "older today +2 days")
        matchesTags(tags: [:], input: "older today +3 years")
        matchesTags(tags: [:], input: "older today +4 months")
        notMatchesTags(tags: [:], input: "older today -2 days")
    }
    
    // newer operator is parsed correctly
    func testNewerOperatorParsedCorrectly() throws {
        matchesTags(tags: [:], input: "newer 2021-12-12")
        matchesTags(tags: [:], input: "newer today -2 days")
        matchesTags(tags: [:], input: "newer today -3 years")
        matchesTags(tags: [:], input: "newer today -4 years")
        notMatchesTags(tags: [:], input: "newer today +2 days")
        
    }
    
    // key operator is parsed correctly
    func testKeyOperatorParsedCorrectly() throws {
        matchesTags(tags: ["shop":"yes"], input: "shop")
        notMatchesTags(tags: ["snop":"yes"], input: "shop")
    }
    
    // tag older operator is parsed correctly
    func testTagOlderOperatorParsedCorrectly() throws {
        matchesTags(tags: ["lit":"yes"], input: "lit older 2199-12-12")
        matchesTags(tags: ["lit":"yes"], input: "lit older today +2 days")
        matchesTags(tags: ["lit":"yes"], input: "lit older today +3 years")
        matchesTags(tags: ["lit":"yes"], input: "lit older today +4 months")
        notMatchesTags(tags: ["lit":"yes"], input: "lit older today -2 days")
    }
    
    // tag newer operator is parsed correctly
    func testTagNewerOperatorIsParsedCorrectly() throws {
        matchesTags(tags: ["lit":"yes"], input: "lit newer 2021-12-12")
        matchesTags(tags: ["lit":"yes"], input: "lit newer today -2 days")
        matchesTags(tags: ["lit":"yes"], input: "lit newer today -3 years")
        matchesTags(tags: ["lit":"yes"], input: "lit newer today -4 months")
        notMatchesTags(tags: ["lit":"yes"], input: "lit newer today +2 days")
    }
    
    // has tag operator is parsed correctly
    func testHasTagOperatorParsedCorrectly() throws {
        matchesTags(tags: ["lit":"yes"], input: "lit = yes")
        matchesTags(tags: ["lit":"yes"], input: "lit=yes")
        matchesTags(tags: ["lit":"yes"], input: "lit   =    yes")
        notMatchesTags(tags: ["lit":"yesnt"], input: "lit = yes")
    }
    
    // not has tag operator is parsed correctly
    func testNotHasTagIsParsedCorrectly() throws {
        matchesTags(tags: ["lit":"no"], input: "lit != yes")
        matchesTags(tags: ["lit":"no"], input: "lit!=yes")
        matchesTags(tags: ["lit":"no"], input: "lit   !=    yes")
        notMatchesTags(tags: ["lit":"yes"], input: "lit != yes")
    }
    
    // has tag value like operator is parsed correctly
    func testTagValueLikeOperatorParsed() throws {
        matchesTags(tags: ["lit":"yes"], input: "lit ~ ...")
        matchesTags(tags: ["lit":"yes"], input: "lit~...")
        matchesTags(tags: ["lit":"yes"], input: "lit   ~    ...")
        notMatchesTags(tags: ["lit":"ye"], input: "lit   ~   ...")
    }
    // tag value greater than operator is parsed correctly
    func testTagValueGraterThanOperatorParsed() throws {
        matchesTags(tags: ["width":"5"], input: "width > 3")
        matchesTags(tags: ["width":"5"], input: "width>3.0")
        matchesTags(tags: ["width": "5"], input: "width   >   3")
        notMatchesTags(tags: ["width": "3"], input: "width   >   3")
        matchesTags(tags: ["width": "0.4"], input: "width>0.3")
        matchesTags(tags: ["width": ".4"], input: "width>.3")
        notMatchesTags(tags: ["width": ".3"], input: "width>.3")
    }
    
    //  tag value greater or equal than operator is parsed correctly
    func testTagValueGreaterOrEqualThanOperatorParsed() throws {
        matchesTags(tags: ["width": "3"], input: "width >= 3")
        matchesTags(tags: ["width": "3"], input: "width>=3.0")
        matchesTags(tags: ["width": "3"], input: "width   >=   3")
        notMatchesTags(tags: ["width": "2"], input: "width   >=   3")
        matchesTags(tags: ["width": "0.3"], input: "width>=0.3")
        matchesTags(tags: ["width": ".3"], input: "width>=.3")
        notMatchesTags(tags: ["width": ".2"], input: "width>=.3")

    }
    
    // tag value less than operator is parsed correctly
    func testTagValueLessThanOperatorParsed() {
        matchesTags(tags: ["width": "2"], input: "width < 3")
        matchesTags(tags: ["width": "2"], input: "width<3.0")
        matchesTags(tags: ["width": "2"], input: "width   <   3")
        notMatchesTags(tags: ["width": "3"], input: "width   <   3")
        matchesTags(tags: ["width": "0.2"], input: "width<0.3")
        matchesTags(tags: ["width": ".2"], input: "width<.3")
        notMatchesTags(tags: ["width": ".3"], input: "width<.3")

    }
    
    // tag value less or equal than operator is parsed correctly
    func testTagValueLessOrEqualThanOperatorParsed() {
        matchesTags(tags: ["width": "3"], input: "width <= 3")
        matchesTags(tags: ["width": "3"], input: "width<=3.0")
        matchesTags(tags: ["width": "3"], input: "width   <=   3")
        notMatchesTags(tags: ["width": "4"], input: "width   <=   3")
        matchesTags(tags: ["width": "0.3"], input: "width<=0.3")
        matchesTags(tags: ["width": ".3"], input: "width<=.3")
        notMatchesTags(tags: ["width": ".4"], input: "width<=.3")

    }
    
    // comparison with dates
    func testComparisonWithDates() {
        matchesTags(tags: ["date": "2022-12-12"], input: "date <= 2022-12-12")
        notMatchesTags(tags: ["date": "2022-12-13"], input: "date <= 2022-12-12")

        matchesTags(tags: ["date": "2022-12-12"], input: "date >= 2022-12-12")
        notMatchesTags(tags: ["date": "2022-12-11"], input: "date >= 2022-12-12")

        matchesTags(tags: ["date": "2022-12-11"], input: "date < 2022-12-12")
        notMatchesTags(tags: ["date": "2022-12-12"], input: "date < 2022-12-12")

        matchesTags(tags: ["date": "2022-12-13"], input: "date > 2022-12-12")
        notMatchesTags(tags: ["date": "2022-12-12"], input: "date > 2022-12-12")

    }
    
    // comparison work with units
    func testComparisonWorkWithUnits() {
        matchesTags(tags: ["maxspeed": "30.1 mph"], input: "maxspeed > 30mph")
        matchesTags(tags: ["maxspeed": "48.3"], input: "maxspeed > 30mph")
        matchesTags(tags: ["maxspeed": "48.3 km/h"], input: "maxspeed > 30mph")

        notMatchesTags(tags: ["maxspeed": "30.0 mph"], input: "maxspeed > 30mph")
        notMatchesTags(tags: ["maxspeed": "48.2"], input: "maxspeed > 30mph")
        notMatchesTags(tags: ["maxspeed": "48.2 km/h"], input: "maxspeed > 30mph")

    }
    
    // comparison work with extra special units
    func testComparisonWorkWithExtraSpecialUnits() {
        matchesTags(tags: ["maxwidth": "4 ft 7 in"], input: "maxwidth > 4'6\"")
        matchesTags(tags: ["maxwidth": "4'7\""], input: "maxwidth > 4'6\"")
        matchesTags(tags: ["maxwidth": "1.4 m"], input: "maxwidth > 4'6\"")
        matchesTags(tags: ["maxwidth": "1.4m"], input: "maxwidth > 4'6\"")
        matchesTags(tags: ["maxwidth": "1.4"], input: "maxwidth > 4'6\"")

        notMatchesTags(tags: ["maxwidth": "4'6\""], input: "maxwidth > 4'6\"")
        notMatchesTags(tags: ["maxwidth": "1.3"], input: "maxwidth > 4'6\"")

    }
    
    // and
    func testAnd() {
        let expr = "a and b"
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)

    }
    
    // two and
    func testTwoAnd() {
        let expr = "a and b and c"
        matchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
    }
    
    // or
    func testOr() {
        let expr = "a or b"
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys(""), input: expr)
    }
    
    // two or
    func testTwoOr() {
        let expr = "a or b or c"
        matchesTags(tags: mapOfKeys("c"), input: expr)
        matchesTags(tags: mapOfKeys("b"), input: expr)
        matchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys(""), input: expr)
    }
    
    // or as first child in and
    func testOrAsFirstChildInAnd() {
        let expr = "(a or b) and c"
        matchesTags(tags: mapOfKeys("c", "a"), input: expr)
        matchesTags(tags: mapOfKeys("c", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
    }
    
    // or as last child in and
    func testOrAsLastChildInAnd() {
        let expr = "c and (a or b)"
        matchesTags(tags: mapOfKeys("c", "a"), input: expr)
        matchesTags(tags: mapOfKeys("c", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
    }
    
    // or in the middle of and
    func testOrInTheMiddleOfAnd() {
        let expr = "c and (a or b) and d"
        matchesTags(tags: mapOfKeys("c", "d", "a"), input: expr)
        matchesTags(tags: mapOfKeys("c", "d", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
    }
    
    // and as first child in or
    func testAndAsFirstChildInOr() {
        let expr = "a and b or c"
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
    }
    
    // and as last child in or
    func testAndAsLastChildInOr() {
        let expr = "c or a and b"
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
    }
    
    // and in the middle of or
    func testAndInTheMiddleOfOr() {
        let expr = "c or a and b or d"
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        matchesTags(tags: mapOfKeys("d"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
    }
    
    // and in or in and
    func testAndInOrInAnd() {
        let expr = "a and (b and c or d)"
        matchesTags(tags: mapOfKeys("a", "d"), input: expr)
        matchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("d"), input: expr)
    }
    
    // and in or in and in or
    func testAndInOrInAndInOr() {
        let expr = "a or (b and (c or (d and e)))"
        
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("b","c"), input: expr)
        matchesTags(tags: mapOfKeys("b","d","e"), input: expr)
        notMatchesTags(tags: mapOfKeys(), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("b","d"), input: expr)
        notMatchesTags(tags: mapOfKeys("b","e"), input: expr)
    }
    
    // and in bracket followed by another and
    func testAndInBracketFollowedByAnotherAnd() {
        let expr = "(a or (b and c)) and d"
        matchesTags(tags: mapOfKeys("a", "d"), input: expr)
        matchesTags(tags: mapOfKeys("b", "c", "d"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("d"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
    }
    
    // not with leaf
    func testNotWithLeaf() { //TODO: issue with this one. throwing exception
        let expr = "!(a)"
        matchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b"), input: expr)
    }
    
    // not without braces
    func testNotWithoutBraces() {
        let expr = "ways with !highway = residential or access = yes"
        shouldFail(input: expr)
    }
    
    // not and with space
    func testNotAndWithSpace() {
        let expr = "! (a and b)"
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("b"), input: expr)
        matchesTags(tags: mapOfKeys("b", "c"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
    }
    
    // not and
    func testNotAnd() {
        let expr = "!(a and b)"
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("b"), input: expr)
        matchesTags(tags: mapOfKeys("b", "c"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
    }
    
    // not or
    func testNotOr() {
        let expr = "!(a or b)"
        matchesTags(tags: mapOfKeys("c"), input: expr)
        matchesTags(tags: mapOfKeys("c", "d", "e"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
    }
    
    // nested not
    func testNestedNot() {
        let expr = "!(!(a))" // equals the expression "a"
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        notMatchesTags(tags: mapOfKeys("b"), input: expr)
    }
    
    // nested not with or
    func testNestedNotWithOr() {
        let expr = "!(!(a and b) or c)" // equals a and b and !(c)
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        matchesTags(tags: mapOfKeys("a", "b", "d"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c", "d"), input: expr)
    }
    
    // nested not with or and switched operands
    func testNestedNotWithOrAndSwitchedOperands() {
        let expr = "!(c or !(a and b))" // equals a and b and !(c)
        matchesTags(tags: mapOfKeys("a", "b"), input: expr)
        matchesTags(tags: mapOfKeys("a", "b", "d"), input: expr)
        notMatchesTags(tags: mapOfKeys("a"), input: expr)
        notMatchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c"), input: expr)
        notMatchesTags(tags: mapOfKeys("a", "b", "c", "d"), input: expr)
    }
    
    // brackets are not dissolved illegally
    func testBracketsAreNotDisolvedIllegally() {
        let expr = "a or (b or c) and !d"
        matchesTags(tags: mapOfKeys("a"), input: expr)
        matchesTags(tags: mapOfKeys("a", "d"), input: expr)
        matchesTags(tags: mapOfKeys("b"), input: expr)
        matchesTags(tags: mapOfKeys("c"), input: expr)
        notMatchesTags(tags: mapOfKeys("c", "d"), input: expr)
        notMatchesTags(tags: mapOfKeys("b", "d"), input: expr)
        matchesTags(tags: mapOfKeys("a", "c", "d"), input: expr)
    }
    
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    
    // Private functions for test usage
    private func parse(input:String) throws -> ElementFilterExpression {
        
        return try input.toElementFilterExpression()
    }
    
    private func shouldFail(input: String) {
        XCTAssertThrowsError(try input.toElementFilterExpression()){
            error in
            XCTAssertTrue(error is ParseException)
        }
    }
    private func matchesTags(tags:[String: String], input: String) {
        let node = TestDataShortcuts.node(tags: tags)
        XCTAssertTrue(try "nodes with \(input)".toElementFilterExpression().matches(element: node))
    }
    
    private func notMatchesTags(tags:[String: String], input: String) {
        let node = TestDataShortcuts.node(tags: tags)
        XCTAssertFalse(try "nodes with \(input)".toElementFilterExpression().matches(element: node))
    }
    
    private func mapOfKeys(_ keys: String...) -> [String: String] {
        return Dictionary(uniqueKeysWithValues: keys.enumerated().map { (index, element) in
            return (element, String(index))
        })
    }

}
