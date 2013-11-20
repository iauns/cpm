#ifndef CENTRAL_EXP_H
#define CENTRAL_EXP_H

#include <string>
#include "inc1.hpp"
#include "inc2.hpp"

namespace CPM_CENTRAL_EXP_NS {

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

std::string centralExpFunction(const CentralExportedClass& myStruct);

} // namespace CPM_CENTRAL_EXP_NS 

#endif

