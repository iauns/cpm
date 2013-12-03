#ifndef MAIN_CENTRAL_H
#define MAIN_CENTRAL_H

#include <string>

namespace CPM_CENTRAL_NS {

class CentralExportedClass
{
public:
  CentralExportedClass() :
      num1(83),
      num2(234),
      str("Initial String")
  {}

  std::string render();

  int num1;
  int num2;
  std::string str;
};

std::string centralFunction(CentralExportedClass& myStruct);
std::string centralFunction2(int num);

} // namespace CPM_CENTRAL_NS 

#endif

