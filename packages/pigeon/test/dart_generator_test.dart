// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:path/path.dart' as path;
import 'package:pigeon/ast.dart';
import 'package:pigeon/dart_generator.dart';
import 'package:pigeon/generator_tools.dart';
import 'package:test/test.dart';

void main() {
  test('gen one class', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'dataType1',
              isNullable: true,
            ),
            name: 'field1'),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Foobar'));
    expect(code, contains('  dataType1? field1;'));
  });

  test('gen one enum', () {
    final Enum anEnum = Enum(
      name: 'Foobar',
      members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'two'),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[],
      enums: <Enum>[anEnum],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('enum Foobar'));
    expect(code, contains('  one,'));
    expect(code, contains('  two,'));
  });

  test('gen one host api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: 'input')
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Api'));
    expect(code, contains('Future<Output> doSomething(Input arg_input)'));
  });

  test('host multiple args', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'add',
          arguments: <NamedType>[
            NamedType(
                name: 'x',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
            NamedType(
                name: 'y',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
          ],
          returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        )
      ])
    ], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Api'));
    expect(code, contains('Future<int> add(int arg_x, int arg_y)'));
    expect(code, contains('await channel.send(<Object?>[arg_x, arg_y])'));
  });

  test('flutter multiple args', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'add',
          arguments: <NamedType>[
            NamedType(
                name: 'x',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
            NamedType(
                name: 'y',
                type:
                    const TypeDeclaration(isNullable: false, baseName: 'int')),
          ],
          returnType: const TypeDeclaration(baseName: 'int', isNullable: false),
        )
      ])
    ], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Api'));
    expect(code, contains('int add(int x, int y)'));
    expect(code,
        contains('final List<Object?> args = (message as List<Object?>?)!'));
    expect(code, contains('final int? arg_x = (args[0] as int?)'));
    expect(code, contains('final int? arg_y = (args[1] as int?)'));
    expect(code, contains('final int output = api.add(arg_x!, arg_y!)'));
  });

  test('nested class', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[
      Class(
        name: 'Input',
        fields: <NamedType>[
          NamedType(
              type: const TypeDeclaration(
                baseName: 'String',
                isNullable: true,
              ),
              name: 'input')
        ],
      ),
      Class(
        name: 'Nested',
        fields: <NamedType>[
          NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: true,
              ),
              name: 'nested')
        ],
      )
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(
      code,
      contains(
        'nested?.encode(),',
      ),
    );
    expect(
      code.replaceAll('\n', ' ').replaceAll('  ', ''),
      contains(
        'nested: result[0] != null ? Input.decode(result[0]! as List<Object?>) : null',
      ),
    );
  });

  test('nested non-nullable class', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[
      Class(
        name: 'Input',
        fields: <NamedType>[
          NamedType(
              type: const TypeDeclaration(
                baseName: 'String',
                isNullable: false,
              ),
              name: 'input')
        ],
      ),
      Class(
        name: 'Nested',
        fields: <NamedType>[
          NamedType(
              type: const TypeDeclaration(
                baseName: 'Input',
                isNullable: false,
              ),
              name: 'nested')
        ],
      )
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(
      code,
      contains(
        'nested.encode(),',
      ),
    );
    expect(
      code.replaceAll('\n', ' ').replaceAll('  ', ''),
      contains(
        'nested: Input.decode(result[0]! as List<Object?>)',
      ),
    );
  });

  test('flutterapi', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: 'input')
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('abstract class Api'));
    expect(code, contains('static void setup(Api'));
    expect(code, contains('Output doSomething(Input input)'));
  });

  test('host void', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<void> doSomething'));
    expect(code, contains('return;'));
  });

  test('flutter void return', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    // The next line verifies that we're not setting a variable to the value of "doSomething", but
    // ignores the line where we assert the value of the argument isn't null, since on that line
    // we mention "doSomething" in the assertion message.
    expect(code, isNot(matches('[^!]=.*doSomething')));
    expect(code, contains('doSomething('));
  });

  test('flutter void argument', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, matches('output.*=.*doSomething[(][)]'));
    expect(code, contains('Output doSomething();'));
  });

  test('flutter enum argument with enum class', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'EnumClass',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType:
              const TypeDeclaration(baseName: 'EnumClass', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'EnumClass', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'Enum',
              isNullable: true,
            ),
            name: 'enum1')
      ]),
    ], enums: <Enum>[
      Enum(
        name: 'Enum',
        members: <EnumMember>[
          EnumMember(name: 'one'),
          EnumMember(name: 'two'),
        ],
      )
    ]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('enum1?.index,'));
    expect(code, contains('? Enum.values[result[0]! as int]'));
    expect(code, contains('EnumClass doSomething(EnumClass arg0);'));
  });

  test('primitive enum host', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Bar', location: ApiLocation.host, methods: <Method>[
        Method(
            name: 'bar',
            returnType: const TypeDeclaration.voidDeclaration(),
            arguments: <NamedType>[
              NamedType(
                  name: 'foo',
                  type:
                      const TypeDeclaration(baseName: 'Foo', isNullable: true))
            ])
      ])
    ], classes: <Class>[], enums: <Enum>[
      Enum(name: 'Foo', members: <EnumMember>[
        EnumMember(name: 'one'),
        EnumMember(name: 'two'),
      ])
    ]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('enum Foo {'));
    expect(code, contains('Future<void> bar(Foo? arg_foo) async'));
    expect(code, contains('channel.send(<Object?>[arg_foo?.index])'));
  });

  test('flutter non-nullable enum argument with enum class', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'EnumClass',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType:
              const TypeDeclaration(baseName: 'EnumClass', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'EnumClass', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'Enum',
              isNullable: false,
            ),
            name: 'enum1')
      ]),
    ], enums: <Enum>[
      Enum(
        name: 'Enum',
        members: <EnumMember>[
          EnumMember(name: 'one'),
          EnumMember(name: 'two'),
        ],
      )
    ]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('enum1.index,'));
    expect(code, contains('enum1: Enum.values[result[0]! as int]'));
  });

  test('host void argument', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
        )
      ])
    ], classes: <Class>[
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, matches('channel.send[(]null[)]'));
  });

  test('mock dart handler', () {
    final Root root = Root(apis: <Api>[
      Api(
          name: 'Api',
          location: ApiLocation.host,
          dartHostTestHandler: 'ApiMock',
          methods: <Method>[
            Method(
              name: 'doSomething',
              arguments: <NamedType>[
                NamedType(
                    type: const TypeDeclaration(
                      baseName: 'Input',
                      isNullable: false,
                    ),
                    name: '')
              ],
              returnType:
                  const TypeDeclaration(baseName: 'Output', isNullable: false),
            ),
            Method(
              name: 'voidReturner',
              arguments: <NamedType>[
                NamedType(
                    type: const TypeDeclaration(
                      baseName: 'Input',
                      isNullable: false,
                    ),
                    name: '')
              ],
              returnType: const TypeDeclaration.voidDeclaration(),
            )
          ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer mainCodeSink = StringBuffer();
    final StringBuffer testCodeSink = StringBuffer();
    generateDart(DartOptions(), root, mainCodeSink);
    final String mainCode = mainCodeSink.toString();
    expect(mainCode, isNot(contains(r"import 'fo\'o.dart';")));
    expect(mainCode, contains('class Api {'));
    expect(mainCode, isNot(contains('abstract class ApiMock')));
    expect(mainCode, isNot(contains('.ApiMock.doSomething')));
    expect(mainCode, isNot(contains("'${Keys.result}': output")));
    expect(mainCode, isNot(contains('return <Object>[];')));
    generateTestDart(
      DartOptions(),
      root,
      testCodeSink,
      sourceOutPath: "fo'o.dart",
      testOutPath: 'test.dart',
    );
    final String testCode = testCodeSink.toString();
    expect(testCode, contains(r"import 'fo\'o.dart';"));
    expect(testCode, isNot(contains('class Api {')));
    expect(testCode, contains('abstract class ApiMock'));
    expect(testCode, isNot(contains('.ApiMock.doSomething')));
    expect(testCode, contains('output'));
    expect(testCode, contains('return <Object?>[];'));
  });

  test('gen one async Flutter Api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('abstract class Api'));
    expect(code, contains('Future<Output> doSomething(Input arg0);'));
    expect(
        code, contains('final Output output = await api.doSomething(arg0!);'));
  });

  test('gen one async Flutter Api with void return', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType: const TypeDeclaration.voidDeclaration(),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, isNot(matches('=.s*doSomething')));
    expect(code, contains('await api.doSomething('));
    expect(code, isNot(contains('._toMap()')));
  });

  test('gen one async Host Api', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Api'));
    expect(code, matches('Output.*doSomething.*Input'));
  });

  test('async host void argument', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ]),
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, matches('channel.send[(]null[)]'));
  });

  Iterable<String> makeIterable(String string) sync* {
    yield string;
  }

  test('header', () {
    final Root root = Root(apis: <Api>[], classes: <Class>[], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(
      DartOptions(copyrightHeader: makeIterable('hello world')),
      root,
      sink,
    );
    final String code = sink.toString();
    expect(code, startsWith('// hello world'));
  });

  test('generics', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
                baseName: 'List',
                isNullable: true,
                typeArguments: <TypeDeclaration>[
                  TypeDeclaration(baseName: 'int', isNullable: true)
                ]),
            name: 'field1'),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Foobar'));
    expect(code, contains('  List<int?>? field1;'));
  });

  test('map generics', () {
    final Class klass = Class(
      name: 'Foobar',
      fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
                baseName: 'Map',
                isNullable: true,
                typeArguments: <TypeDeclaration>[
                  TypeDeclaration(baseName: 'String', isNullable: true),
                  TypeDeclaration(baseName: 'int', isNullable: true),
                ]),
            name: 'field1'),
      ],
    );
    final Root root = Root(
      apis: <Api>[],
      classes: <Class>[klass],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('class Foobar'));
    expect(code, contains('  Map<String?, int?>? field1;'));
  });

  test('host generics argument', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    type: const TypeDeclaration(
                        baseName: 'List',
                        isNullable: false,
                        typeArguments: <TypeDeclaration>[
                          TypeDeclaration(baseName: 'int', isNullable: true)
                        ]),
                    name: 'arg')
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('doit(List<int?> arg'));
  });

  test('flutter generics argument with void return', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    type: const TypeDeclaration(
                        baseName: 'List',
                        isNullable: false,
                        typeArguments: <TypeDeclaration>[
                          TypeDeclaration(baseName: 'int', isNullable: true)
                        ]),
                    name: 'arg')
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('doit(List<int?> arg'));
  });

  test('host generics return', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                  baseName: 'List',
                  isNullable: false,
                  typeArguments: <TypeDeclaration>[
                    TypeDeclaration(baseName: 'int', isNullable: true)
                  ]),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<List<int?>> doit('));
    expect(code,
        contains('return (replyList[0] as List<Object?>?)!.cast<int?>();'));
  });

  test('flutter generics argument non void return', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                  baseName: 'List',
                  isNullable: false,
                  typeArguments: <TypeDeclaration>[
                    TypeDeclaration(baseName: 'int', isNullable: true)
                  ]),
              arguments: <NamedType>[
                NamedType(
                    type: const TypeDeclaration(
                        baseName: 'List',
                        isNullable: false,
                        typeArguments: <TypeDeclaration>[
                          TypeDeclaration(baseName: 'int', isNullable: true)
                        ]),
                    name: 'foo')
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('List<int?> doit('));
    expect(
        code,
        contains(
            'final List<int?>? arg_foo = (args[0] as List<Object?>?)?.cast<int?>()'));
    expect(code, contains('final List<int?> output = api.doit(arg_foo!)'));
  });

  test('return nullable host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<int?> doit()'));
    expect(code, contains('return (replyList[0] as int?);'));
  });

  test('return nullable collection host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                  baseName: 'List',
                  isNullable: true,
                  typeArguments: <TypeDeclaration>[
                    TypeDeclaration(baseName: 'int', isNullable: true)
                  ]),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<List<int?>?> doit()'));
    expect(code,
        contains('return (replyList[0] as List<Object?>?)?.cast<int?>();'));
  });

  test('return nullable async host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              arguments: <NamedType>[],
              isAsynchronous: true)
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<int?> doit()'));
    expect(code, contains('return (replyList[0] as int?);'));
  });

  test('return nullable flutter', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('int? doit();'));
    expect(code, contains('final int? output = api.doit();'));
  });

  test('return nullable async flutter', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: true,
              ),
              arguments: <NamedType>[],
              isAsynchronous: true)
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<int?> doit();'));
    expect(code, contains('final int? output = await api.doit();'));
  });

  test('platform error for return nil on nonnull', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration(
                baseName: 'int',
                isNullable: false,
              ),
              arguments: <NamedType>[])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(
        code,
        contains(
            'Host platform returned null value for non-null return value.'));
  });

  test('nullable argument host', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.host, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    name: 'foo',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: true,
                    )),
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('Future<void> doit(int? arg_foo) async {'));
  });

  test('nullable argument flutter', () {
    final Root root = Root(
      apis: <Api>[
        Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
          Method(
              name: 'doit',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                    name: 'foo',
                    type: const TypeDeclaration(
                      baseName: 'int',
                      isNullable: true,
                    )),
              ])
        ])
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('void doit(int? foo);'));
  });

  test('deduces package name', () {
    final Directory tempDir = Directory.systemTemp.createTempSync('pigeon');
    try {
      final Directory foo = Directory(path.join(tempDir.path, 'lib', 'foo'));
      foo.createSync(recursive: true);
      final File pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      pubspecFile.writeAsStringSync('''
name: foobar
''');
      final Root root =
          Root(classes: <Class>[], apis: <Api>[], enums: <Enum>[]);
      final StringBuffer sink = StringBuffer();
      generateTestDart(
        DartOptions(),
        root,
        sink,
        sourceOutPath: path.join(foo.path, 'bar.dart'),
        testOutPath: path.join(tempDir.path, 'test', 'bar_test.dart'),
      );
      final String code = sink.toString();
      expect(code, contains("import 'package:foobar/foo/bar.dart';"));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('transfers documentation comments', () {
    final List<String> comments = <String>[
      ' api comment',
      ' api method comment',
      ' class comment',
      ' class field comment',
      ' enum comment',
      ' enum member comment',
    ];
    int count = 0;

    final List<String> unspacedComments = <String>['////////'];
    int unspacedCount = 0;

    final Root root = Root(
      apis: <Api>[
        Api(
          name: 'Api',
          location: ApiLocation.flutter,
          documentationComments: <String>[comments[count++]],
          methods: <Method>[
            Method(
              name: 'method',
              returnType: const TypeDeclaration.voidDeclaration(),
              documentationComments: <String>[comments[count++]],
              arguments: <NamedType>[
                NamedType(
                  name: 'field',
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: true,
                  ),
                ),
              ],
            )
          ],
        )
      ],
      classes: <Class>[
        Class(
          name: 'class',
          documentationComments: <String>[comments[count++]],
          fields: <NamedType>[
            NamedType(
                documentationComments: <String>[comments[count++]],
                type: const TypeDeclaration(
                    baseName: 'Map',
                    isNullable: true,
                    typeArguments: <TypeDeclaration>[
                      TypeDeclaration(baseName: 'String', isNullable: true),
                      TypeDeclaration(baseName: 'int', isNullable: true),
                    ]),
                name: 'field1'),
          ],
        ),
      ],
      enums: <Enum>[
        Enum(
          name: 'enum',
          documentationComments: <String>[
            comments[count++],
            unspacedComments[unspacedCount++]
          ],
          members: <EnumMember>[
            EnumMember(
              name: 'one',
              documentationComments: <String>[comments[count++]],
            ),
            EnumMember(name: 'two'),
          ],
        ),
      ],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    for (final String comment in comments) {
      expect(code, contains('///$comment'));
    }
    expect(code, contains('/// ///'));
  });

  test('doesnt create codecs if no custom datatypes', () {
    final Root root = Root(
      apis: <Api>[
        Api(
          name: 'Api',
          location: ApiLocation.flutter,
          methods: <Method>[
            Method(
              name: 'method',
              returnType: const TypeDeclaration.voidDeclaration(),
              arguments: <NamedType>[
                NamedType(
                  name: 'field',
                  type: const TypeDeclaration(
                    baseName: 'int',
                    isNullable: true,
                  ),
                ),
              ],
            )
          ],
        )
      ],
      classes: <Class>[],
      enums: <Enum>[],
    );
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, isNot(contains('extends StandardMessageCodec')));
    expect(code, contains('StandardMessageCodec'));
  });

  test('creates custom codecs if custom datatypes present', () {
    final Root root = Root(apis: <Api>[
      Api(name: 'Api', location: ApiLocation.flutter, methods: <Method>[
        Method(
          name: 'doSomething',
          arguments: <NamedType>[
            NamedType(
                type: const TypeDeclaration(
                  baseName: 'Input',
                  isNullable: false,
                ),
                name: '')
          ],
          returnType:
              const TypeDeclaration(baseName: 'Output', isNullable: false),
          isAsynchronous: true,
        )
      ])
    ], classes: <Class>[
      Class(name: 'Input', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'input')
      ]),
      Class(name: 'Output', fields: <NamedType>[
        NamedType(
            type: const TypeDeclaration(
              baseName: 'String',
              isNullable: true,
            ),
            name: 'output')
      ])
    ], enums: <Enum>[]);
    final StringBuffer sink = StringBuffer();
    generateDart(DartOptions(), root, sink);
    final String code = sink.toString();
    expect(code, contains('extends StandardMessageCodec'));
  });

  test('host test code handles enums', () {
    final Root root = Root(
      apis: <Api>[
        Api(
            name: 'Api',
            location: ApiLocation.host,
            dartHostTestHandler: 'ApiMock',
            methods: <Method>[
              Method(
                  name: 'doit',
                  returnType: const TypeDeclaration.voidDeclaration(),
                  arguments: <NamedType>[
                    NamedType(
                        type: const TypeDeclaration(
                          baseName: 'Enum',
                          isNullable: false,
                        ),
                        name: 'anEnum')
                  ])
            ])
      ],
      classes: <Class>[],
      enums: <Enum>[
        Enum(
          name: 'Enum',
          members: <EnumMember>[
            EnumMember(name: 'one'),
            EnumMember(name: 'two'),
          ],
        )
      ],
    );
    final StringBuffer sink = StringBuffer();
    generateTestDart(
      DartOptions(),
      root,
      sink,
      sourceOutPath: 'code.dart',
      testOutPath: 'test.dart',
    );
    final String testCode = sink.toString();
    expect(
        testCode,
        contains(
            'final Enum? arg_anEnum = args[0] == null ? null : Enum.values[args[0] as int]'));
  });
}
