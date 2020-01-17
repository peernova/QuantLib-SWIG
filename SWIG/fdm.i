/*
 Copyright (C) 2020 Klaus Spanderen

 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it
 under the terms of the QuantLib license.  You should have received a
 copy of the license along with this program; if not, please email
 <quantlib-dev@lists.sf.net>. The license is also available online at
 <http://quantlib.org/license.shtml>.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

#ifndef quantlib_fdm_i
#define quantlib_fdm_i


%include stl.i
%include common.i
%include vectors.i
%include functions.i
%include options.i
%include basketoptions.i
%include dividends.i
%include settings.i
%include shortratemodels.i

%include boost_shared_ptr.i


// mesher

%{
using QuantLib::Fdm1dMesher;
using QuantLib::FdmBlackScholesMesher;
using QuantLib::Concentrating1dMesher;
using QuantLib::ExponentialJump1dMesher;
using QuantLib::FdmQuantoHelper;
using QuantLib::FdmCEV1dMesher;
using QuantLib::FdmHestonVarianceMesher;
using QuantLib::FdmHestonLocalVolatilityVarianceMesher;
using QuantLib::Uniform1dMesher;
using QuantLib::FdmSimpleProcess1dMesher;
using QuantLib::Predefined1dMesher;
using QuantLib::Glued1dMesher;
%}


%shared_ptr(Fdm1dMesher)
class Fdm1dMesher {
  public:
    explicit Fdm1dMesher(Size size);
    
    Size size() const;
    Real dplus(Size index) const;
    Real dminus(Size index) const;
    Real location(Size index) const;
    const std::vector<Real>& locations();
};

#if defined(SWIGCSHARP)
SWIG_STD_VECTOR_ENHANCED( boost::shared_ptr<Fdm1dMesher> )
#endif
namespace std {
    %template(Fdm1dMesherVector) vector<boost::shared_ptr<Fdm1dMesher> >;
}

%shared_ptr(FdmBlackScholesMesher)
class FdmBlackScholesMesher : public Fdm1dMesher {
  public:
    #if defined(SWIGPYTHON)
    %feature("kwargs") FdmBlackScholesMesher;
    #endif
      
    FdmBlackScholesMesher(
        Size size,
        const boost::shared_ptr<GeneralizedBlackScholesProcess>& process,
        Time maturity, Real strike,
        doubleOrNull xMinConstraint = Null<Real>(),
        doubleOrNull xMaxConstraint = Null<Real>(),
        Real eps = 0.0001,
        Real scaleFactor = 1.5,
        const std::pair<Real, Real>& cPoint
            = (std::pair<Real, Real>(Null<Real>(), Null<Real>())),
        const std::vector<boost::shared_ptr<Dividend> >& dividendSchedule 
            = std::vector<boost::shared_ptr<Dividend> >(),
        const boost::shared_ptr<FdmQuantoHelper>& fdmQuantoHelper
            = boost::shared_ptr<FdmQuantoHelper>(),
        Real spotAdjustment = 0.0);

    static boost::shared_ptr<GeneralizedBlackScholesProcess> processHelper(
         const Handle<Quote>& s0,
         const Handle<YieldTermStructure>& rTS,
         const Handle<YieldTermStructure>& qTS,
         Volatility vol);
};

%template(Concentrating1dMesherPoint) boost::tuple<Real, Real, bool>;
%template(Concentrating1dMesherPointVector) std::vector<boost::tuple<Real, Real, bool> >;


%shared_ptr(Concentrating1dMesher)
class Concentrating1dMesher : public Fdm1dMesher {
  public:
    Concentrating1dMesher(
        Real start, Real end, Size size,
        const std::pair<Real, Real>& cPoints
                 = (std::pair<Real, Real>(Null<Real>(), Null<Real>())),
        const bool requireCPoint = false);

    Concentrating1dMesher(
        Real start, Real end, Size size,
        const std::vector<boost::tuple<Real, Real, bool> >& cPoints,
        Real tol = 1e-8);
};

%shared_ptr(ExponentialJump1dMesher)
class ExponentialJump1dMesher : public Fdm1dMesher {
   public:
     ExponentialJump1dMesher(Size steps, Real beta, Real jumpIntensity, 
                             Real eta, Real eps = 1e-3);
};

%shared_ptr(FdmCEV1dMesher)
class FdmCEV1dMesher : public Fdm1dMesher {
  public:
    #if defined(SWIGPYTHON)
    %feature("kwargs") FdmCEV1dMesher;
    #endif

    FdmCEV1dMesher(
        Size size,
        Real f0, Real alpha, Real beta,
        Time maturity,
        Real eps = 0.0001,
        Real scaleFactor = 1.5,
        const std::pair<Real, Real>& cPoint
            = (std::pair<Real, Real>(Null<Real>(), Null<Real>())));
};

%shared_ptr(FdmHestonVarianceMesher)
class FdmHestonVarianceMesher : public Fdm1dMesher {
  public:
    FdmHestonVarianceMesher(
        Size size,
        const boost::shared_ptr<HestonProcess> & process,
        Time maturity, Size tAvgSteps = 10, Real epsilon = 0.0001);

    Real volaEstimate() const;
};

%shared_ptr(FdmHestonLocalVolatilityVarianceMesher)
class FdmHestonLocalVolatilityVarianceMesher : public Fdm1dMesher {
  public:
    FdmHestonLocalVolatilityVarianceMesher(
        Size size,
        const boost::shared_ptr<HestonProcess>& process,
        const boost::shared_ptr<LocalVolTermStructure>& leverageFct,
        Time maturity, Size tAvgSteps = 10, Real epsilon = 0.0001);

    Real volaEstimate() const;
};


%shared_ptr(FdmSimpleProcess1dMesher)
class FdmSimpleProcess1dMesher : public Fdm1dMesher {
  public:
      FdmSimpleProcess1dMesher(
        Size size,
        const boost::shared_ptr<StochasticProcess1D>& process,
        Time maturity, Size tAvgSteps = 10, Real epsilon = 0.0001,
        doubleOrNull mandatoryPoint = Null<Real>());
};

%shared_ptr(Uniform1dMesher)
class Uniform1dMesher : public Fdm1dMesher {
  public:
    Uniform1dMesher(Real start, Real end, Size size);
};

%shared_ptr(Predefined1dMesher)
class Predefined1dMesher : public Fdm1dMesher {
  public:
    explicit Predefined1dMesher(const std::vector<Real>& x);
};

%shared_ptr(Glued1dMesher)
class Glued1dMesher : public Fdm1dMesher {
  public:
    %extend {
        Glued1dMesher(
            const boost::shared_ptr<Fdm1dMesher>& leftMesher,
            const boost::shared_ptr<Fdm1dMesher>& rightMesher) {
            
            return new Glued1dMesher(*leftMesher, *rightMesher);
        }
    }
};


%{
using QuantLib::FdmLinearOpIterator;
using QuantLib::FdmLinearOpLayout;
using QuantLib::FdmMesher;
using QuantLib::FdmMesherComposite;
%}


class FdmLinearOpIterator {
  public:
  
#if defined(SWIGPYTHON) || defined(SWIGR)
    %extend {
        FdmLinearOpIterator(
            const std::vector<unsigned int>& dim,
            const std::vector<unsigned int>& coordinates, Size index) {
            
            std::vector<Size> _dim(dim.size());
            std::copy(dim.begin(), dim.end(), _dim.begin());
            
            std::vector<Size> _coordinates(coordinates.size());
            std::copy(coordinates.begin(), coordinates.end(), 
                _coordinates.begin());
            
            return new FdmLinearOpIterator(_dim, _coordinates, index);
         }
         
         std::vector<unsigned int> coordinates() {
            const std::vector<Size>& c = self->coordinates();
             std::vector<unsigned int> tmp(c.size());
             std::copy(c.begin(), c.end(), tmp.begin());
             
             return tmp;
         }
     }
#else  
    FdmLinearOpIterator(
        const std::vector<Size>& dim,
        const std::vector<Size>& coordinates, Size index);

    const std::vector<Size>& coordinates();
#endif

    %extend {
        void increment() {
            ++(*$self);
        }
        bool notEqual(const FdmLinearOpIterator& iterator) {
            return self->operator!=(iterator);
        }
    }    
    
    Size index() const;
};

%shared_ptr(FdmLinearOpLayout)
class FdmLinearOpLayout {
  public:
  
#if defined(SWIGPYTHON) || defined(SWIGR)
    %extend {
        FdmLinearOpLayout(const std::vector<unsigned int>& dim) {
            std::vector<Size> _dim(dim.size());
            std::copy(dim.begin(), dim.end(), _dim.begin());
            
            return new FdmLinearOpLayout(_dim);
        }

        Size index(const std::vector<unsigned int>& coordinates) const {
            std::vector<Size> tmp(coordinates.size());
            std::copy(coordinates.begin(), coordinates.end(), tmp.begin());
            
            return self->index(tmp);
        }
        
        const std::vector<unsigned int> spacing() {        
            std::vector<unsigned int> tmp(self->spacing().size());
            std::copy(self->spacing().begin(), self->spacing().end(),
                tmp.begin());
                
             return tmp;
        }
        const std::vector<unsigned int> dim() const {
            std::vector<unsigned int> tmp(self->dim().size());
            std::copy(self->dim().begin(), self->dim().end(),
                tmp.begin());
                
             return tmp;
        }        
    }
#else  
    explicit FdmLinearOpLayout(const std::vector<Size>& dim);

    const std::vector<Size>& spacing();
    const std::vector<Size>& dim() const;

    Size index(const std::vector<Size>& coordinates) const;
    
#endif
    
    FdmLinearOpIterator begin() const;
    FdmLinearOpIterator end() const;
    
    Size size() const;
    
    Size neighbourhood(const FdmLinearOpIterator& iterator,
                       Size i, Integer offset) const;

    Size neighbourhood(const FdmLinearOpIterator& iterator,
                       Size i1, Integer offset1,
                       Size i2, Integer offset2) const;

    %extend {
        FdmLinearOpIterator iter_neighbourhood(
            const FdmLinearOpIterator& iterator, Size i, Integer offset) const {
            
            return self->iter_neighbourhood(iterator, i, offset);
        }
    }
};


%shared_ptr(FdmMesher)
class FdmMesher {
  private:
    FdmMesher();
};

%shared_ptr(FdmMesherComposite)
class FdmMesherComposite : public FdmMesher {
  public:
    FdmMesherComposite(
        const boost::shared_ptr<FdmLinearOpLayout>& layout,
        const std::vector<boost::shared_ptr<Fdm1dMesher> > & mesher);

    // convenient constructors
    explicit FdmMesherComposite(
        const std::vector<boost::shared_ptr<Fdm1dMesher> > & mesher);
    explicit FdmMesherComposite(
        const boost::shared_ptr<Fdm1dMesher>& mesher);
    FdmMesherComposite(const boost::shared_ptr<Fdm1dMesher>& m1,
                       const boost::shared_ptr<Fdm1dMesher>& m2);
    FdmMesherComposite(const boost::shared_ptr<Fdm1dMesher>& m1,
                       const boost::shared_ptr<Fdm1dMesher>& m2,
                       const boost::shared_ptr<Fdm1dMesher>& m3);
    FdmMesherComposite(const boost::shared_ptr<Fdm1dMesher>& m1,
                       const boost::shared_ptr<Fdm1dMesher>& m2,
                       const boost::shared_ptr<Fdm1dMesher>& m3,
                       const boost::shared_ptr<Fdm1dMesher>& m4);


    Real dplus(const FdmLinearOpIterator& iter, Size direction) const;
    Real dminus(const FdmLinearOpIterator& iter, Size direction) const;
    Real location(const FdmLinearOpIterator& iter, Size direction) const;
    %extend {
        Array locations(Size direction) const {
            return self->locations(direction);
        }
        
        boost::shared_ptr<FdmLinearOpLayout> layout() {
            const std::vector<boost::shared_ptr<Fdm1dMesher> >& meshers = 
                self->getFdm1dMeshers();
                
            std::vector<Size> dim(meshers.size());
            
            for (Size i=0; i < dim.size(); ++i)
                dim[i] = meshers[i]->size();
                
            return boost::make_shared<FdmLinearOpLayout>(dim);            
        }
    }

    const std::vector<boost::shared_ptr<Fdm1dMesher> >&
        getFdm1dMeshers() const;
};


// fdm operators

%{
using QuantLib::FdmLinearOp;
using QuantLib::FdmLinearOpComposite;
%}


%shared_ptr(FdmLinearOp)
class FdmLinearOp {
  public:
    virtual ~FdmLinearOp();
    virtual Disposable<Array> apply(const Array& r) const = 0;
};

%shared_ptr(FdmLinearOpComposite)
class FdmLinearOpComposite : public FdmLinearOp {
  public:
    virtual Size size() const = 0;
    virtual void setTime(Time t1, Time t2) = 0;
    virtual Disposable<Array> apply_mixed(const Array& r) const = 0;    
    virtual Disposable<Array> 
        apply_direction(Size direction, const Array& r) const = 0;
    virtual Disposable<Array> 
        solve_splitting(Size direction, const Array& r, Real s) const = 0;
    virtual Disposable<Array> 
        preconditioner(const Array& r, Real s) const = 0;
};


#if defined(SWIGPYTHON)
%{
class FdmLinearOpCompositeProxy : public FdmLinearOpComposite {
  public:
      FdmLinearOpCompositeProxy(PyObject* callback) : callback_(callback) {
        Py_XINCREF(callback_);
    }
    
    FdmLinearOpCompositeProxy& operator=(const FdmLinearOpCompositeProxy& f) {
        if ((this != &f) && (callback_ != f.callback_)) {
            Py_XDECREF(callback_);
            callback_ = f.callback_;
            Py_XINCREF(callback_);
        }
        return *this;
    }
    
    ~FdmLinearOpCompositeProxy() {
        Py_XDECREF(callback_);
    }
        
    Size size() const {
        PyObject* pyResult = PyObject_CallMethod(callback_,"size", NULL);
        
        QL_ENSURE(pyResult != NULL,
                  "failed to call size() on Python object");
                  
        Size result = PyInt_AsLong(pyResult);
        Py_XDECREF(pyResult);
        
        return result;    
    }

    void setTime(Time t1, Time t2) {
        PyObject* pyResult 
            = PyObject_CallMethod(callback_,"setTime","dd", t1, t2);
            
        QL_ENSURE(pyResult != NULL,
                  "failed to call setTime() on Python object");
                                    
        Py_XDECREF(pyResult);
    }

    Disposable<Array> apply(const Array& r) const {
        return apply(r, "apply");        
    }

    Disposable<Array> apply_mixed(const Array& r) const {
        return apply(r, "apply_mixed");        
    }
    
    Disposable<Array> apply_direction(Size direction, const Array& r) const {
        PyObject* pyArray = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&r), SWIGTYPE_p_Array, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, "apply_direction", "kO", 
                (unsigned long)(direction), pyArray);
            
        Py_XDECREF(pyArray); 
            
        return extractArray(pyResult, "apply_direction");        
    }
    
    Disposable<Array> solve_splitting(
        Size direction, const Array& r, Real s) const {

        PyObject* pyArray = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&r), SWIGTYPE_p_Array, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, "solve_splitting", "kOd", 
                (unsigned long)(direction), pyArray, s);
            
        Py_XDECREF(pyArray); 
            
        return extractArray(pyResult, "solve_splitting");        
    }
    
    Disposable<Array> preconditioner(const Array& r, Real s) const {
        PyObject* pyArray = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&r), SWIGTYPE_p_Array, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, "preconditioner", "Od",pyArray, s);
            
        Py_XDECREF(pyArray); 
            
        return extractArray(pyResult, "preconditioner");        
    }

  private:
    Disposable<Array> extractArray(
        PyObject* pyResult, const std::string& methodName) const {
          
        QL_ENSURE(pyResult != NULL,
                  "failed to call " + methodName + " on Python object");

        QL_ENSURE(pyResult != Py_None, methodName + " returned None");
            
        Array* ptr;            
        const int err = SWIG_ConvertPtr(
            pyResult, (void **) &ptr, SWIGTYPE_p_Array, SWIG_POINTER_EXCEPTION);

        if (err != 0) {
            Py_XDECREF(pyResult);
            QL_FAIL("return type must be of type QuantLib Array in " 
                + methodName);
        }
        
        Array tmp(*ptr);          
        Py_XDECREF(pyResult);
         
        return tmp;
    }
      
    Disposable<Array> apply(
        const Array& r, const std::string& methodName) const {

        PyObject* pyArray = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&r), SWIGTYPE_p_Array, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, methodName.c_str(), "O", pyArray);
            
        Py_XDECREF(pyArray); 
        
        return extractArray(pyResult, methodName);        
    }
        
    PyObject* callback_;    
};
%}

%shared_ptr(FdmLinearOpCompositeProxy)
class FdmLinearOpCompositeProxy : public FdmLinearOpComposite {
  public:
    FdmLinearOpCompositeProxy(PyObject* callback);
    
    Size size() const;
    void setTime(Time t1, Time t2);
      
    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> apply_mixed(const Array& r) const;    
    Disposable<Array> apply_direction(Size direction, const Array& r) const;
    Disposable<Array> solve_splitting(Size direction, const Array& r, Real s) const;
    Disposable<Array> preconditioner(const Array& r, Real s) const;
};

#elif defined(SWIGJAVA) || defined(SWIGCSHARP)

%{
class FdmLinearOpCompositeDelegate {
  public:
      virtual ~FdmLinearOpCompositeDelegate() {}
      
    virtual Size size() const {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.size is missing");        
    }
    
    virtual void setTime(Time t1, Time t2) {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.setTime is missing");    
    }
      
    virtual Array apply(const Array& r) const {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.apply is missing");    
    }
    
    virtual Array apply_mixed(const Array& r) const {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.apply_mixed is missing");    
    }    
    
    virtual Array apply_direction(Size direction, const Array& r) const {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.apply_direction is missing");    
    }
    
    virtual Array solve_splitting(Size direction, const Array& r, Real s) const {
        QL_FAIL("implementation of FdmLinearOpCompositeDelegate.solve_splitting is missing");        
    }    
    
    virtual Array preconditioner(const Array& r, Real dt) const {
        return solve_splitting(0, r, dt);
    }
};

class FdmLinearOpCompositeProxy : public FdmLinearOpComposite {
  public:
    FdmLinearOpCompositeProxy(FdmLinearOpCompositeDelegate* delegate)
    : delegate_(delegate) {}
      
    Size size() const { return delegate_->size(); }
    void setTime(Time t1, Time t2) { delegate_->setTime(t1, t2); }
    
    Disposable<Array> apply(const Array& r) const {
        Array retVal = delegate_->apply(r);
        return retVal;
    }
    Disposable<Array> apply_mixed(const Array& r) const {
        Array retVal = delegate_->apply_mixed(r);
        return retVal;
    }        
    Disposable<Array> apply_direction(Size direction, const Array& r) const {
        Array retVal = delegate_->apply_direction(direction, r);
        return retVal;
    }
    Disposable<Array> solve_splitting(
        Size direction, const Array& r, Real s) const {
        Array retVal = delegate_->solve_splitting(direction, r, s);
        return retVal;
    }
    Disposable<Array> preconditioner(const Array& r, Real s) const {
        Array retVal = delegate_->preconditioner(r, s);
        return retVal;
    }
               
  private:
      FdmLinearOpCompositeDelegate* const delegate_; 
};
%}

%shared_ptr(FdmLinearOpCompositeProxy)
class FdmLinearOpCompositeProxy : public FdmLinearOpComposite {
  public:
    FdmLinearOpCompositeProxy(FdmLinearOpCompositeDelegate* delegate);
      
    Size size() const;
    void setTime(Time t1, Time t2);
    
    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> apply_mixed(const Array& r) const;
    Disposable<Array> apply_direction(Size direction, const Array& r) const;
    Disposable<Array> solve_splitting(
        Size direction, const Array& r, Real s) const;
    Disposable<Array> preconditioner(const Array& r, Real s) const;
};


%feature("director") FdmLinearOpCompositeDelegate;

class FdmLinearOpCompositeDelegate {
  public:
      virtual ~FdmLinearOpCompositeDelegate();
      
    virtual Size size() const;
    virtual void setTime(Time t1, Time t2);
      
    virtual Array apply(const Array& r) const;
    virtual Array apply_mixed(const Array& r) const;    
    virtual Array apply_direction(Size direction, const Array& r) const;
    virtual Array solve_splitting(
        Size direction, const Array& r, Real s) const;    
    virtual Array preconditioner(const Array& r, Real dt) const;
};
    
#endif

%{
using QuantLib::FdmDiscountDirichletBoundary;
using QuantLib::FdmDirichletBoundary;
using QuantLib::BoundaryCondition;
using QuantLib::FdmTimeDepDirichletBoundary;
using QuantLib::FdmBlackScholesOp;
using QuantLib::Fdm2dBlackScholesOp;
using QuantLib::FdmBatesOp;
using QuantLib::FdmCEVOp;
using QuantLib::FdmG2Op;
using QuantLib::FdmHestonHullWhiteOp;
using QuantLib::FdmHestonOp;
using QuantLib::FdmHullWhiteOp;
using QuantLib::FdmLocalVolFwdOp;
using QuantLib::FdmOrnsteinUhlenbeckOp;
using QuantLib::FdmSabrOp;
using QuantLib::FdmZabrOp;
using QuantLib::FdmDupire1dOp;
using QuantLib::FdmBlackScholesFwdOp;
using QuantLib::FdmHestonFwdOp;
using QuantLib::FdmSquareRootFwdOp;

typedef std::vector<boost::shared_ptr<BoundaryCondition<FdmLinearOp> > > FdmBoundaryConditionSet;
%}

%shared_ptr(BoundaryCondition<FdmLinearOp>);

template <class Operator>
class BoundaryCondition {
   %rename(NoSide) None;

  public:    
    enum Side { None, Upper, Lower }; 

    virtual ~BoundaryCondition();
    virtual void applyBeforeApplying(Operator&) const = 0;
    virtual void applyAfterApplying(Array&) const = 0;
    virtual void applyBeforeSolving(Operator&, Array& rhs) const = 0;
    virtual void applyAfterSolving(Array&) const = 0;
    virtual void setTime(Time t) = 0;
};


typedef std::vector<boost::shared_ptr<BoundaryCondition<FdmLinearOp> > > FdmBoundaryConditionSet;

%template(BoundaryConditionFdmLinearOp) BoundaryCondition<FdmLinearOp>; 

#if defined(SWIGCSHARP)
SWIG_STD_VECTOR_ENHANCED( boost::shared_ptr<BoundaryCondition<FdmLinearOp> > )
#endif

%template(FdmBoundaryConditionSet) std::vector<boost::shared_ptr<BoundaryCondition<FdmLinearOp> > >;

%shared_ptr(FdmDirichletBoundary)
class FdmDirichletBoundary : public BoundaryCondition<FdmLinearOp> {
  public:
    typedef BoundaryCondition<FdmLinearOp>::Side Side;

    FdmDirichletBoundary(const boost::shared_ptr<FdmMesher>& mesher,
                         Real valueOnBoundary, Size direction, Side side);

    void applyBeforeApplying(FdmLinearOp&) const;
    void applyBeforeSolving(FdmLinearOp&, Array&) const;
    void applyAfterApplying(Array&) const;
    void applyAfterSolving(Array&) const;
    void setTime(Time);
    
    Real applyAfterApplying(Real x, Real value) const;
};

%shared_ptr(FdmDiscountDirichletBoundary)
class FdmDiscountDirichletBoundary
        : public BoundaryCondition<FdmLinearOp> {
  public:
    typedef BoundaryCondition<FdmLinearOp>::Side Side;

    FdmDiscountDirichletBoundary(
        const boost::shared_ptr<FdmMesher>& mesher,
        const boost::shared_ptr<YieldTermStructure>& rTS,
        Time maturityTime,
        Real valueOnBoundary,
        Size direction, Side side);

    void setTime(Time);
    void applyBeforeApplying(FdmLinearOp&) const;
    void applyBeforeSolving(FdmLinearOp&, Array&) const;
    void applyAfterApplying(Array&) const;
    void applyAfterSolving(Array&) const;
};

#if defined(SWIGPYTHON) || defined(SWIGJAVA) || defined(SWIGCSHARP)
%shared_ptr(FdmTimeDepDirichletBoundary)
class FdmTimeDepDirichletBoundary : public BoundaryCondition<FdmLinearOp> {
  public:
    typedef BoundaryCondition<FdmLinearOp>::Side Side;

    %extend {
#if defined(SWIGPYTHON)
        FdmTimeDepDirichletBoundary(
            const boost::shared_ptr<FdmMesher>& mesher,
            PyObject* function,
            Size direction, Side side) {
            
            const boost::function<Real(Real)> f = UnaryFunction(function);
            return new FdmTimeDepDirichletBoundary(
                mesher, f, direction, side);
        }
#elif defined(SWIGJAVA) || defined(SWIGCSHARP)
        FdmTimeDepDirichletBoundary(
            const boost::shared_ptr<FdmMesher>& mesher,
            UnaryFunctionDelegate* function,
            Size direction, Side side) {
            
            const boost::function<Real(Real)> f = UnaryFunction(function);
            return new FdmTimeDepDirichletBoundary(
                mesher, f, direction, side);        
         }
#endif
    }
    
    void setTime(Time);
    void applyBeforeApplying(FdmLinearOp&) const;
    void applyBeforeSolving(FdmLinearOp&, Array&) const;
    void applyAfterApplying(Array&) const;
    void applyAfterSolving(Array&) const;
};
#endif


%define DeclareOperator(OperatorName, constructor)
%shared_ptr(OperatorName)
class OperatorName : public FdmLinearOpComposite {
  public:
    OperatorName(constructor);
    
    Size size() const;
    void setTime(Time t1, Time t2);

    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> apply_mixed(const Array& r) const;
    Disposable<Array> apply_direction(Size direction, const Array& r) const;
    Disposable<Array>
        solve_splitting(Size direction, const Array& r, Real s) const;
    Disposable<Array> preconditioner(const Array& r, Real s) const;    
};
%enddef

%define __COMMA ,
%enddef

DeclareOperator(FdmBatesOp, 
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<BatesProcess>& batesProcess __COMMA
    const FdmBoundaryConditionSet& bcSet __COMMA
    Size integroIntegrationOrder __COMMA
    const boost::shared_ptr<FdmQuantoHelper>& quantoHelper
                                = boost::shared_ptr<FdmQuantoHelper>()                                    
)

DeclareOperator(FdmBlackScholesOp, 
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<GeneralizedBlackScholesProcess>& process __COMMA
    Real strike __COMMA
    bool localVol = false __COMMA
    doubleOrNull illegalLocalVolOverwrite = -Null<Real>() __COMMA
    Size direction = 0 __COMMA
    const boost::shared_ptr<FdmQuantoHelper>& quantoHelper
        = boost::shared_ptr<FdmQuantoHelper>()
)

DeclareOperator(Fdm2dBlackScholesOp, 
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<GeneralizedBlackScholesProcess>& p1 __COMMA
    const boost::shared_ptr<GeneralizedBlackScholesProcess>& p2 __COMMA
    Real correlation __COMMA
    Time maturity __COMMA
    bool localVol = false __COMMA
    doubleOrNull illegalLocalVolOverwrite = -Null<Real>()
)        

DeclareOperator(FdmCEVOp, 
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<YieldTermStructure>& rTS __COMMA
    Real f0 __COMMA Real alpha __COMMA Real beta __COMMA
    Size direction
)

DeclareOperator(FdmG2Op,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<G2>& model __COMMA
    Size direction1 __COMMA Size direction2
)

DeclareOperator(FdmHestonHullWhiteOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<HestonProcess>& hestonProcess __COMMA
    const boost::shared_ptr<HullWhiteProcess>& hwProcess __COMMA
    Real equityShortRateCorrelation
)

DeclareOperator(FdmHestonOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<HestonProcess>& hestonProcess __COMMA
    const boost::shared_ptr<FdmQuantoHelper>& quantoHelper
        = boost::shared_ptr<FdmQuantoHelper>() __COMMA
    const boost::shared_ptr<LocalVolTermStructure>& leverageFct
        = boost::shared_ptr<LocalVolTermStructure>()
)

DeclareOperator(FdmHullWhiteOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<HullWhite>& model __COMMA
    Size direction
)

DeclareOperator(FdmLocalVolFwdOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<Quote>& spot __COMMA
    const boost::shared_ptr<YieldTermStructure>& rTS __COMMA
    const boost::shared_ptr<YieldTermStructure>& qTS __COMMA
    const boost::shared_ptr<LocalVolTermStructure>& localVol __COMMA
    Size direction = 0
)

DeclareOperator(FdmOrnsteinUhlenbeckOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<OrnsteinUhlenbeckProcess>& p __COMMA
    const boost::shared_ptr<YieldTermStructure>& rTS __COMMA
    Size direction = 0
)

DeclareOperator(FdmSabrOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<YieldTermStructure>& rTS __COMMA
    Real f0 __COMMA
    Real alpha __COMMA
    Real beta __COMMA
    Real nu __COMMA
    Real rho
)

DeclareOperator(FdmZabrOp,
    const boost::shared_ptr<FdmMesher> & mesher __COMMA 
    const Real beta __COMMA
    const Real nu __COMMA
    const Real rho __COMMA 
    const Real gamma
)

DeclareOperator(FdmDupire1dOp,
    const boost::shared_ptr<FdmMesher> & mesher __COMMA
    const Array &localVolatility
)

DeclareOperator(FdmBlackScholesFwdOp,
    const boost::shared_ptr<FdmMesher>& mesher __COMMA
    const boost::shared_ptr<GeneralizedBlackScholesProcess>& process __COMMA
    Real strike __COMMA
    bool localVol = false __COMMA
    Real illegalLocalVolOverwrite = -Null<Real>() __COMMA
    Size direction = 0
)

%shared_ptr(FdmSquareRootFwdOp)
class FdmSquareRootFwdOp : public FdmLinearOpComposite {
  public:
    enum TransformationType { Plain, Power, Log };

    FdmSquareRootFwdOp(
        const boost::shared_ptr<FdmMesher>& mesher,
        Real kappa, Real theta, Real sigma,
        Size direction,
        TransformationType type = Plain);

    Size size()    const;
    void setTime(Time t1, Time t2);

    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> apply_mixed(const Array& r) const;
    Disposable<Array> apply_direction(Size direction,
                                      const Array& r) const;
    Disposable<Array> solve_splitting(Size direction,
                                      const Array& r, Real s) const;
    Disposable<Array> preconditioner(const Array& r, Real s) const;
};

%shared_ptr(FdmHestonFwdOp)
class FdmHestonFwdOp : public FdmLinearOpComposite {
  public:
    FdmHestonFwdOp(
        const boost::shared_ptr<FdmMesher>& mesher,
        const boost::shared_ptr<HestonProcess>& process,
        FdmSquareRootFwdOp::TransformationType type 
            = FdmSquareRootFwdOp::Plain,
        const boost::shared_ptr<LocalVolTermStructure> & leverageFct
            = boost::shared_ptr<LocalVolTermStructure>());

    Size size() const;
    void setTime(Time t1, Time t2);

    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> apply_mixed(const Array& r) const;

    Disposable<Array> apply_direction(Size direction,
                                      const Array& r) const;
    Disposable<Array> solve_splitting(Size direction,
                                      const Array& r, Real s) const;
    Disposable<Array> preconditioner(const Array& r, Real s) const;
};

%{
using QuantLib::TripleBandLinearOp;
using QuantLib::FirstDerivativeOp;
using QuantLib::SecondDerivativeOp;
using QuantLib::NinePointLinearOp;
%}

%shared_ptr(TripleBandLinearOp)
class TripleBandLinearOp : public FdmLinearOp {
  public:
    TripleBandLinearOp(Size direction,
                       const boost::shared_ptr<FdmMesher>& mesher);

    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> solve_splitting(const Array& r, Real a,
                                      Real b = 1.0) const;

    Disposable<TripleBandLinearOp> mult(const Array& u) const;
    Disposable<TripleBandLinearOp> multR(const Array& u) const;
    Disposable<TripleBandLinearOp> add(const TripleBandLinearOp& m) const;
    Disposable<TripleBandLinearOp> add(const Array& u) const;

    void axpyb(const Array& a, const TripleBandLinearOp& x,
               const TripleBandLinearOp& y, const Array& b);

    void swap(TripleBandLinearOp& m);
};

%shared_ptr(Disposable<TripleBandLinearOp>)
%template(DisposableTripleBandLinearOp) Disposable<TripleBandLinearOp>;

%shared_ptr(FirstDerivativeOp)
class FirstDerivativeOp : public TripleBandLinearOp {
  public:
    FirstDerivativeOp(Size direction,
                      const boost::shared_ptr<FdmMesher>& mesher);
                          
    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> solve_splitting(
        const Array& r, Real a, Real b = 1.0) const;                     
};

%shared_ptr(SecondDerivativeOp)
class SecondDerivativeOp : public TripleBandLinearOp {
  public:
    SecondDerivativeOp(Size direction,
        const boost::shared_ptr<FdmMesher>& mesher);

    Disposable<Array> apply(const Array& r) const;
    Disposable<Array> solve_splitting(
        const Array& r, Real a, Real b = 1.0) const;                     
};

%shared_ptr(NinePointLinearOp)
class NinePointLinearOp : public FdmLinearOp {
  public:
    NinePointLinearOp(Size d0, Size d1,
        const boost::shared_ptr<FdmMesher>& mesher);

    Disposable<Array> apply(const Array& r) const;
};

%shared_ptr(Disposable<NinePointLinearOp>)
%template(DisposableNinePointLinearOp) Disposable<NinePointLinearOp>;


// fdm schemes

%{
using QuantLib::CraigSneydScheme;
using QuantLib::CrankNicolsonScheme;
using QuantLib::ImplicitEulerScheme;
using QuantLib::DouglasScheme;
using QuantLib::ExplicitEulerScheme;
using QuantLib::HundsdorferScheme;
using QuantLib::MethodOfLinesScheme;
using QuantLib::ModifiedCraigSneydScheme;
%}

%shared_ptr(CraigSneydScheme)
class CraigSneydScheme  {
  public:
    CraigSneydScheme(Real theta, Real mu,
        const boost::shared_ptr<FdmLinearOpComposite> & map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};

%shared_ptr(ImplicitEulerScheme)
class ImplicitEulerScheme {
  public:
    enum SolverType { BiCGstab, GMRES };

    #if defined(SWIGPYTHON)
        %feature("kwargs") ImplicitEulerScheme;
    #endif

    ImplicitEulerScheme(
        const boost::shared_ptr<FdmLinearOpComposite>& map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet(),
        Real relTol = 1e-8,
        SolverType solverType = BiCGstab);

    void step(Array& a, Time t);
    void setStep(Time dt);

    Size numberOfIterations() const;
};

%shared_ptr(CrankNicolsonScheme)
class CrankNicolsonScheme  {
  public:
    #if defined(SWIGPYTHON)
        %feature("kwargs") CrankNicolsonScheme;
    #endif
  
    CrankNicolsonScheme(
        Real theta,
        const boost::shared_ptr<FdmLinearOpComposite>& map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet(),
        Real relTol = 1e-8,
        ImplicitEulerScheme::SolverType solverType
            = ImplicitEulerScheme::BiCGstab);

    void step(Array& a, Time t);
    void setStep(Time dt);

    Size numberOfIterations() const;
};

%shared_ptr(DouglasScheme)
class DouglasScheme  {
  public:
    DouglasScheme(Real theta,
        const boost::shared_ptr<FdmLinearOpComposite> & map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};

%shared_ptr(ExplicitEulerScheme)
class ExplicitEulerScheme  {
  public:
    ExplicitEulerScheme(
        const boost::shared_ptr<FdmLinearOpComposite>& map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};

%shared_ptr(HundsdorferScheme)
class HundsdorferScheme  {
  public:
    HundsdorferScheme(Real theta, Real mu,
        const boost::shared_ptr<FdmLinearOpComposite> & map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};

%shared_ptr(MethodOfLinesScheme)
class MethodOfLinesScheme  {
  public:
    MethodOfLinesScheme(
        const Real eps, const Real relInitStepSize,
        const boost::shared_ptr<FdmLinearOpComposite>& map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};

%shared_ptr(ModifiedCraigSneydScheme)
class ModifiedCraigSneydScheme  {
  public:
    ModifiedCraigSneydScheme(Real theta, Real mu,
        const boost::shared_ptr<FdmLinearOpComposite> & map,
        const FdmBoundaryConditionSet& bcSet = FdmBoundaryConditionSet());

    void step(Array& a, Time t);
    void setStep(Time dt);
};


// step condition

%{
using QuantLib::StepCondition;
using QuantLib::FdmSnapshotCondition;
using QuantLib::FdmAmericanStepCondition;
using QuantLib::FdmArithmeticAverageCondition;
using QuantLib::FdmSimpleSwingCondition;
using QuantLib::FdmBermudanStepCondition;
using QuantLib::FdmSimpleStorageCondition;
using QuantLib::FdmSimpleSwingCondition;
using QuantLib::FdmDividendHandler;
using QuantLib::FdmInnerValueCalculator;
using QuantLib::FdmCellAveragingInnerValue;
using QuantLib::FdmLogInnerValue;
using QuantLib::FdmLogBasketInnerValue;
using QuantLib::FdmZeroInnerValue;
using QuantLib::FdmAffineModelSwapInnerValue;
using QuantLib::FdmStepConditionComposite;
%}

%shared_ptr(StepCondition<Array>);

template <class array_type>
class StepCondition {
  public:
    virtual void applyTo(array_type& a, Time t) const = 0;
};

%template(FdmStepCondition) StepCondition<Array>;

#if defined(SWIGPYTHON)
%{
class FdmStepConditionProxy : public StepCondition<Array> {
  public:
    FdmStepConditionProxy(PyObject* callback) : callback_(callback) {
        Py_XINCREF(callback_);
    }
    
    FdmStepConditionProxy& operator=(const FdmStepConditionProxy& f) {
        if ((this != &f) && (callback_ != f.callback_)) {
            Py_XDECREF(callback_);
            callback_ = f.callback_;
            Py_XINCREF(callback_);
        }
        return *this;
    }
    
    ~FdmStepConditionProxy() {
        Py_XDECREF(callback_);
    }
        
    void applyTo(Array& a, Time t) const {
        PyObject* pyArray = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&a), SWIGTYPE_p_Array, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, "applyTo", "Od",pyArray, t);
            
        Py_XDECREF(pyArray);
    }
    
  private:       
    PyObject* callback_;    
};
%}

%shared_ptr(FdmStepConditionProxy)
class FdmStepConditionProxy : public StepCondition<Array> {
  public:
    FdmStepConditionProxy(PyObject* callback);

    void applyTo(Array& a, Time t) const;
};

#elif defined(SWIGJAVA) || defined(SWIGCSHARP)

%{
class FdmStepConditionDelegate {
  public:
    virtual ~FdmStepConditionDelegate() {}
      
    virtual void applyTo(Array& a, Time t) const {
        QL_FAIL("implementation of FdmStepCondition.applyTo is missing");        
    }
};

class FdmStepConditionProxy : public StepCondition<Array> {
  public:
    FdmStepConditionProxy(FdmStepConditionDelegate* delegate)
    : delegate_(delegate) {}
    
    void applyTo(Array& a, Time t) const {
        delegate_->applyTo(a, t);
    }
    
  private:  
      FdmStepConditionDelegate* const delegate_; 
};
%}

%shared_ptr(FdmStepConditionProxy)
class FdmStepConditionProxy : public StepCondition<Array> {
  public:
    FdmStepConditionProxy(FdmStepConditionDelegate* delegate);
      
    void applyTo(Array& a, Time t) const;
};


%feature("director") FdmStepConditionDelegate;

class FdmStepConditionDelegate {
  public:
      virtual ~FdmStepConditionDelegate();
      
    virtual void applyTo(Array& a, Time t) const;
};
    
#endif


%shared_ptr(FdmInnerValueCalculator)
class FdmInnerValueCalculator {
  public:
    virtual ~FdmInnerValueCalculator();

    virtual Real innerValue(const FdmLinearOpIterator& iter, Time t) = 0;
    virtual Real avgInnerValue(const FdmLinearOpIterator& iter, Time t) = 0;
};

#if defined(SWIGPYTHON)
%{
class FdmInnerValueCalculatorProxy : public FdmInnerValueCalculator {
  public:
    FdmInnerValueCalculatorProxy(PyObject* callback) : callback_(callback) {
        Py_XINCREF(callback_);
    }
    
    FdmInnerValueCalculatorProxy& operator=(const FdmInnerValueCalculatorProxy& f) {
        if ((this != &f) && (callback_ != f.callback_)) {
            Py_XDECREF(callback_);
            callback_ = f.callback_;
            Py_XINCREF(callback_);
        }
        return *this;
    }
    
    ~FdmInnerValueCalculatorProxy() {
        Py_XDECREF(callback_);
    }
        
    Real innerValue(const FdmLinearOpIterator& iter, Time t) {
        return getValue(iter, t, "innerValue");
    }

    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t) {
        return getValue(iter, t, "avgInnerValue");
    }
    
  private: 
      Real getValue(const FdmLinearOpIterator& iter, Time t, const std::string& methodName) {
        PyObject* pyIter = SWIG_NewPointerObj(
        	SWIG_as_voidptr(&iter), SWIGTYPE_p_FdmLinearOpIterator, SWIG_BUILTIN_INIT | 0);
            
        PyObject* pyResult 
            = PyObject_CallMethod(callback_, methodName.c_str(), "Od",pyIter, t);
                    
        QL_ENSURE(pyResult != NULL, "failed to call innerValue function on Python object");
        
        const Real result = PyFloat_AsDouble(pyResult);

        Py_XDECREF(pyResult);
        
        return result;
      }      
    PyObject* callback_;    
};
%}

%shared_ptr(FdmInnerValueCalculatorProxy)
class FdmInnerValueCalculatorProxy : public FdmInnerValueCalculator {
  public:
    FdmInnerValueCalculatorProxy(PyObject* callback);

    Real innerValue(const FdmLinearOpIterator& iter, Time t);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t);
};

#elif defined(SWIGJAVA) || defined(SWIGCSHARP)

%{
class FdmInnerValueCalculatorDelegate {
  public:
    virtual ~FdmInnerValueCalculatorDelegate() {}
      
    virtual Real innerValue(const FdmLinearOpIterator& iter, Time t) {
        QL_FAIL("implementation of FdmInnerValueCalculatorDelegate.innerValue is missing");        
    }
    virtual Real avgInnerValue(const FdmLinearOpIterator& iter, Time t) {
        QL_FAIL("implementation of FdmInnerValueCalculatorDelegate.avgInnerValue is missing");            
    }
};

class FdmInnerValueCalculatorProxy : public FdmInnerValueCalculator {
  public:
    FdmInnerValueCalculatorProxy(FdmInnerValueCalculatorDelegate* delegate)
    : delegate_(delegate) {}
    
    Real innerValue(const FdmLinearOpIterator& iter, Time t) {
        delegate_->innerValue(iter, t);        
    }
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t) {
        delegate_->avgInnerValue(iter, t);        
    }
    
  private:  
      FdmInnerValueCalculatorDelegate* const delegate_; 
};
%}

%shared_ptr(FdmInnerValueCalculatorProxy)
class FdmInnerValueCalculatorProxy : public FdmInnerValueCalculator {
  public:
    FdmInnerValueCalculatorProxy(FdmInnerValueCalculatorDelegate* delegate);
      
    Real innerValue(const FdmLinearOpIterator& iter, Time t);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t);
};


%feature("director") FdmInnerValueCalculatorDelegate;

class FdmInnerValueCalculatorDelegate {
  public:
      virtual ~FdmInnerValueCalculatorDelegate();
      
    virtual Real innerValue(const FdmLinearOpIterator& iter, Time t);
    virtual Real avgInnerValue(const FdmLinearOpIterator& iter, Time t);
};
#endif


%shared_ptr(FdmCellAveragingInnerValue)
class FdmCellAveragingInnerValue : public FdmInnerValueCalculator {
  public:
  
#if defined(SWIGPYTHON)
    %extend {
        FdmCellAveragingInnerValue(
            const boost::shared_ptr<Payoff>& payoff,
            const boost::shared_ptr<FdmMesher>& mesher,
            Size direction,
            PyObject* gridMapping) {
            
                UnaryFunction f(gridMapping);
                return new FdmCellAveragingInnerValue(payoff, mesher, direction, f);
        }
    }
#elif defined(SWIGJAVA) || defined(SWIGCSHARP)
    %extend {
        FdmCellAveragingInnerValue(
            const boost::shared_ptr<Payoff>& payoff,
            const boost::shared_ptr<FdmMesher>& mesher,
            Size direction,        
            UnaryFunctionDelegate* gridMapping) {
            
                UnaryFunction f(gridMapping);
                return new FdmCellAveragingInnerValue(payoff, mesher, direction, f);            
        }
    }
#endif

    %extend {
        FdmCellAveragingInnerValue(
            const boost::shared_ptr<Payoff>& payoff,
            const boost::shared_ptr<FdmMesher>& mesher,
            Size direction) {
                return new FdmCellAveragingInnerValue(payoff, mesher, direction);            
        }
    }
        
    Real innerValue(const FdmLinearOpIterator& iter, Time);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t);
};


%shared_ptr(FdmLogInnerValue)
class FdmLogInnerValue : public FdmCellAveragingInnerValue {
  public:
    FdmLogInnerValue(const boost::shared_ptr<Payoff>& payoff,
                     const boost::shared_ptr<FdmMesher>& mesher,
                     Size direction);

    Real innerValue(const FdmLinearOpIterator& iter, Time);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time);
};


%shared_ptr(FdmLogBasketInnerValue)
class FdmLogBasketInnerValue : public FdmInnerValueCalculator {
  public:
    FdmLogBasketInnerValue(const boost::shared_ptr<BasketPayoff>& payoff,
                           const boost::shared_ptr<FdmMesher>& mesher);

    Real innerValue(const FdmLinearOpIterator& iter, Time);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time);
};

%shared_ptr(FdmZeroInnerValue)
class FdmZeroInnerValue : public FdmInnerValueCalculator {
  public:
    Real innerValue(const FdmLinearOpIterator&, Time);
    Real avgInnerValue(const FdmLinearOpIterator&, Time);
};


%shared_ptr(FdmAffineModelSwapInnerValue<G2>)
%shared_ptr(FdmAffineModelSwapInnerValue<HullWhite>)

#if !defined(SWIGR)
%template(TimeToDateMap) std::map<Time, Date>;

template <class ModelType>
class FdmAffineModelSwapInnerValue : public FdmInnerValueCalculator {
  public:
    FdmAffineModelSwapInnerValue(
        const boost::shared_ptr<ModelType>& disModel,
        const boost::shared_ptr<ModelType>& fwdModel,
        const boost::shared_ptr<VanillaSwap>& swap,
        const std::map<Time, Date>& exerciseDates,
        const boost::shared_ptr<FdmMesher>& mesher,
        Size direction);

    Real innerValue(const FdmLinearOpIterator& iter, Time t);
    Real avgInnerValue(const FdmLinearOpIterator& iter, Time t);
};

%template(FdmAffineG2ModelSwapInnerValue) FdmAffineModelSwapInnerValue<G2>;
%template(FdmAffineHullWhiteModelSwapInnerValue) FdmAffineModelSwapInnerValue<HullWhite>;
#endif

%shared_ptr(FdmSnapshotCondition)
class FdmSnapshotCondition : public StepCondition<Array> {
public:
    explicit FdmSnapshotCondition(Time t);

    void applyTo(Array& a, Time t) const;
    Time getTime() const;       
    const Array& getValues() const;
};

#if defined(SWIGCSHARP)
SWIG_STD_VECTOR_ENHANCED( boost::shared_ptr<StepCondition<Array> > )
#endif

%template(FdmStepConditionVector) std::vector<boost::shared_ptr<StepCondition<Array> > > ; 
 
%shared_ptr(FdmStepConditionComposite)
class FdmStepConditionComposite : public StepCondition<Array> {
public:
    typedef std::vector<boost::shared_ptr<StepCondition<Array> > > Conditions;
    %extend {
        FdmStepConditionComposite(
            const std::vector<Time> & stoppingTimes,
            const std::vector<boost::shared_ptr<StepCondition<Array> > > & conditions) {
            return new FdmStepConditionComposite(
                std::list<std::vector<Time> >(1, stoppingTimes), 
                std::list<boost::shared_ptr<StepCondition<Array> > >(
                    conditions.begin(), conditions.end()));
        }
    }
    
    void applyTo(Array& a, Time t) const;
    const std::vector<Time>& stoppingTimes() const;
    const std::vector<boost::shared_ptr<StepCondition<Array> > > & conditions() const;

    static boost::shared_ptr<FdmStepConditionComposite> joinConditions(
                const boost::shared_ptr<FdmSnapshotCondition>& c1,
                const boost::shared_ptr<FdmStepConditionComposite>& c2);

    static boost::shared_ptr<FdmStepConditionComposite> vanillaComposite(
         const std::vector<boost::shared_ptr<Dividend> >& schedule,
         const boost::shared_ptr<Exercise>& exercise,
         const boost::shared_ptr<FdmMesher>& mesher,
         const boost::shared_ptr<FdmInnerValueCalculator>& calculator,
         const Date& refDate,
         const DayCounter& dayCounter);
};


%shared_ptr(FdmAmericanStepCondition)
class FdmAmericanStepCondition : public StepCondition<Array> {
  public:
    FdmAmericanStepCondition(
        const boost::shared_ptr<FdmMesher> & mesher,
        const boost::shared_ptr<FdmInnerValueCalculator> & calculator);

    void applyTo(Array& a, Time) const;
};

%shared_ptr(FdmArithmeticAverageCondition)
class FdmArithmeticAverageCondition : public StepCondition<Array> {
  public:
    FdmArithmeticAverageCondition(
        const std::vector<Time> & averageTimes,
        Real, Size pastFixings,
        const boost::shared_ptr<FdmMesher> & mesher,
        Size equityDirection);

    void applyTo(Array& a, Time t) const;
};

%shared_ptr(FdmBermudanStepCondition)
class FdmBermudanStepCondition : public StepCondition<Array> {
  public:
    FdmBermudanStepCondition(
        const std::vector<Date> & exerciseDates,
        const Date& referenceDate,
        const DayCounter& dayCounter,
        const boost::shared_ptr<FdmMesher> & mesher,
        const boost::shared_ptr<FdmInnerValueCalculator> & calculator);

    void applyTo(Array& a, Time t) const;
    const std::vector<Time>& exerciseTimes() const;
};

%shared_ptr(FdmSimpleStorageCondition)
class FdmSimpleStorageCondition : public StepCondition<Array> {
  public:
    FdmSimpleStorageCondition(
        const std::vector<Time> & exerciseTimes,
        const boost::shared_ptr<FdmMesher>& mesher,
        const boost::shared_ptr<FdmInnerValueCalculator>& calculator,
        Real changeRate);

    void applyTo(Array& a, Time t) const;
};

%shared_ptr(FdmSimpleSwingCondition)
class FdmSimpleSwingCondition : public StepCondition<Array> {
  public:
      FdmSimpleSwingCondition(
              const std::vector<Time> & exerciseTimes,
              const boost::shared_ptr<FdmMesher>& mesher,
              const boost::shared_ptr<FdmInnerValueCalculator>& calculator,
              Size swingDirection,
              Size minExercises = 0);

    void applyTo(Array& a, Time t) const;
};

%shared_ptr(FdmDividendHandler)
class FdmDividendHandler : public StepCondition<Array> {
  public:
    FdmDividendHandler(const std::vector<boost::shared_ptr<Dividend> >& schedule,
                       const boost::shared_ptr<FdmMesher>& mesher,
                       const Date& referenceDate,
                       const DayCounter& dayCounter,
                       Size equityDirection);
        
    void applyTo(Array& a, Time t) const;
 
    const std::vector<Time>& dividendTimes() const;
    const std::vector<Date>& dividendDates() const;
    const std::vector<Real>& dividends() const;
};


// solver

%{
using QuantLib::FdmSolverDesc;
using QuantLib::Fdm1DimSolver;
using QuantLib::FdmBackwardSolver;
using QuantLib::Fdm2dBlackScholesSolver;
using QuantLib::Fdm2DimSolver;
using QuantLib::Fdm3DimSolver;
using QuantLib::FdmG2Solver;
using QuantLib::FdmHestonHullWhiteSolver;
using QuantLib::FdmHestonSolver;
using QuantLib::FdmHullWhiteSolver;
using QuantLib::FdmNdimSolver;
%}


struct FdmSolverDesc {
  public:
    %extend {
        FdmSolverDesc(
            const boost::shared_ptr<FdmMesher>& mesher,
            const FdmBoundaryConditionSet& bcSet,
            const boost::shared_ptr<FdmStepConditionComposite>& condition,
            const boost::shared_ptr<FdmInnerValueCalculator>& calculator,
            Time maturity,
            Size timeSteps,
            Size dampingSteps) {
            
            const FdmSolverDesc desc = { 
                mesher, bcSet, condition, calculator, 
                maturity, timeSteps, dampingSteps };
            
            return new FdmSolverDesc(desc);            
        }
        
        boost::shared_ptr<FdmMesher> getMesher() const { return self->mesher; }
        const FdmBoundaryConditionSet& getBcSet() const { return self->bcSet; }
        boost::shared_ptr<FdmStepConditionComposite> 
            getStepConditions() const { return self->condition; }
        boost::shared_ptr<FdmInnerValueCalculator> 
            getCalculator() const { return self->calculator; }
        Time getMaturity() const { return self->maturity; }
        Size getTimeSteps() const { return self->timeSteps; }
        Size getDampingSteps() const { return self->dampingSteps; }        
    }
};

%shared_ptr(Fdm1DimSolver)
class Fdm1DimSolver {
  public:
    Fdm1DimSolver(const FdmSolverDesc& solverDesc,
                  const FdmSchemeDesc& schemeDesc,
                  const boost::shared_ptr<FdmLinearOpComposite>& op);

    Real interpolateAt(Real x) const;
    Real thetaAt(Real x) const;

    Real derivativeX(Real x) const;
    Real derivativeXX(Real x) const;
};

%shared_ptr(FdmBackwardSolver)
class FdmBackwardSolver {
  public:    
    FdmBackwardSolver(
      const boost::shared_ptr<FdmLinearOpComposite>& map,
      const FdmBoundaryConditionSet& bcSet,
      const boost::shared_ptr<FdmStepConditionComposite> condition,
      const FdmSchemeDesc& schemeDesc);

    void rollback(Array& a, Time from, Time to,
                  Size steps, Size dampingSteps);
};


%shared_ptr(Fdm2dBlackScholesSolver)
class Fdm2dBlackScholesSolver {
  public:
    #if defined(SWIGPYTHON)
    %feature("kwargs") Fdm2dBlackScholesSolver;
    #endif
    
    %extend {    
        Fdm2dBlackScholesSolver(
            const boost::shared_ptr<GeneralizedBlackScholesProcess>& p1,
            const boost::shared_ptr<GeneralizedBlackScholesProcess>& p2,
            const Real correlation,
            const FdmSolverDesc& solverDesc,
            const FdmSchemeDesc& schemeDesc = FdmSchemeDesc::Hundsdorfer(),
            bool localVol = false,
            Real illegalLocalVolOverwrite = -Null<Real>()) {
                return new Fdm2dBlackScholesSolver(
                    Handle<GeneralizedBlackScholesProcess>(p1), 
                    Handle<GeneralizedBlackScholesProcess>(p2), 
                    correlation, solverDesc, schemeDesc, 
                    localVol, illegalLocalVolOverwrite); 
        }
    }
    
    Real valueAt(Real x, Real y) const;
    Real thetaAt(Real x, Real y) const;

    Real deltaXat(Real x, Real y) const;
    Real deltaYat(Real x, Real y) const;
    Real gammaXat(Real x, Real y) const;
    Real gammaYat(Real x, Real y) const;
    Real gammaXYat(Real x, Real y) const;
};


%shared_ptr(Fdm2DimSolver)
class Fdm2DimSolver {
  public:
    Fdm2DimSolver(const FdmSolverDesc& solverDesc,
                  const FdmSchemeDesc& schemeDesc,
                  const boost::shared_ptr<FdmLinearOpComposite>& op);

    Real interpolateAt(Real x, Real y) const;
    Real thetaAt(Real x, Real y) const;

    Real derivativeX(Real x, Real y) const;
    Real derivativeY(Real x, Real y) const;
    Real derivativeXX(Real x, Real y) const;
    Real derivativeYY(Real x, Real y) const;
    Real derivativeXY(Real x, Real y) const;
};


%shared_ptr(Fdm3DimSolver)
class Fdm3DimSolver {
  public:
    Fdm3DimSolver(const FdmSolverDesc& solverDesc,
                  const FdmSchemeDesc& schemeDesc,
                  const boost::shared_ptr<FdmLinearOpComposite>& op);

    void performCalculations() const;

    Real interpolateAt(Real x, Real y, Rate z) const;
    Real thetaAt(Real x, Real y, Rate z) const;
};


%shared_ptr(FdmG2Solver)
class FdmG2Solver {
  public:
    %extend {
        FdmG2Solver(
            const boost::shared_ptr<G2>& model,
            const FdmSolverDesc& solverDesc,
            const FdmSchemeDesc& schemeDesc = FdmSchemeDesc::Hundsdorfer()) {
                return new FdmG2Solver(Handle<G2>(model), solverDesc, schemeDesc);            
        }
    }
    Real valueAt(Real x, Real y) const;
};


%shared_ptr(FdmHestonHullWhiteSolver)
class FdmHestonHullWhiteSolver {
  public:
    %extend {
        FdmHestonHullWhiteSolver(
            const boost::shared_ptr<HestonProcess>& hestonProcess,
            const boost::shared_ptr<HullWhiteProcess>& hwProcess,
            Rate corrEquityShortRate,
            const FdmSolverDesc& solverDesc,
            const FdmSchemeDesc& schemeDesc = FdmSchemeDesc::Hundsdorfer()) {
                return new FdmHestonHullWhiteSolver(
                    Handle<HestonProcess>(hestonProcess),
                    Handle<HullWhiteProcess>(hwProcess),
                    corrEquityShortRate, solverDesc, schemeDesc);                    
        }
    }
    
    Real valueAt(Real s, Real v, Rate r) const;
    Real thetaAt(Real s, Real v, Rate r) const;
    
    Real deltaAt(Real s, Real v, Rate r, Real eps) const;
    Real gammaAt(Real s, Real v, Rate r, Real eps) const;
};


%shared_ptr(FdmHestonSolver)
class FdmHestonSolver {
  public:
    #if defined(SWIGPYTHON)
    %feature("kwargs") FdmHestonSolver;
    #endif

    %extend {
        FdmHestonSolver(
            const boost::shared_ptr<HestonProcess>& process,
            const FdmSolverDesc& solverDesc,
            const FdmSchemeDesc& schemeDesc = FdmSchemeDesc::Hundsdorfer(),
            const boost::shared_ptr<FdmQuantoHelper>& quantoHelper
                = boost::shared_ptr<FdmQuantoHelper>(),
            const boost::shared_ptr<LocalVolTermStructure>& leverageFct
                = boost::shared_ptr<LocalVolTermStructure>()) {
                
                return new FdmHestonSolver(
                    Handle<HestonProcess>(process),
                    solverDesc, schemeDesc, 
                    Handle<FdmQuantoHelper>(quantoHelper), 
                    leverageFct);
        }
    }
    
    Real valueAt(Real s, Real v) const;
    Real thetaAt(Real s, Real v) const;

    Real deltaAt(Real s, Real v) const;
    Real gammaAt(Real s, Real v) const;

    Real meanVarianceDeltaAt(Real s, Real v) const;
    Real meanVarianceGammaAt(Real s, Real v) const;
};


%shared_ptr(FdmHullWhiteSolver)
class FdmHullWhiteSolver {
  public:
    %extend {
        FdmHullWhiteSolver(
            const boost::shared_ptr<HullWhite>& model,
            const FdmSolverDesc& solverDesc,
            const FdmSchemeDesc& schemeDesc = FdmSchemeDesc::Hundsdorfer()) {
                return new FdmHullWhiteSolver(
                    Handle<HullWhite>(model), solverDesc, schemeDesc);
        }
    }
    Real valueAt(Real r) const;
};


%shared_ptr(FdmNdimSolver<4>);
%shared_ptr(FdmNdimSolver<5>);
%shared_ptr(FdmNdimSolver<6>);

template <Size N>
class FdmNdimSolver {
  public:
    FdmNdimSolver(const FdmSolverDesc& solverDesc,
                  const FdmSchemeDesc& schemeDesc,
                  const boost::shared_ptr<FdmLinearOpComposite>& op);

    Real interpolateAt(const std::vector<Real>& x) const;
    Real thetaAt(const std::vector<Real>& x) const;
};


%template(Fdm4dimSolver) FdmNdimSolver<4>;
%template(Fdm5dimSolver) FdmNdimSolver<5>;
%template(Fdm6dimSolver) FdmNdimSolver<6>;


// utilities

%{
using QuantLib::FdmIndicesOnBoundary;
using QuantLib::RiskNeutralDensityCalculator;
using QuantLib::BSMRNDCalculator;
using QuantLib::CEVRNDCalculator;
using QuantLib::GBSMRNDCalculator;
using QuantLib::HestonRNDCalculator;
using QuantLib::LocalVolRNDCalculator;
using QuantLib::SquareRootProcessRNDCalculator;
%}

%shared_ptr(FdmIndicesOnBoundary)
class FdmIndicesOnBoundary {
  public:
    FdmIndicesOnBoundary(const boost::shared_ptr<FdmLinearOpLayout>& l,
                          Size direction, FdmDirichletBoundary::Side side);

    const std::vector<Size>& getIndices() const;
};


%shared_ptr(RiskNeutralDensityCalculator)
class RiskNeutralDensityCalculator {
  public:
    virtual Real pdf(Real x, Time t) const = 0;
    virtual Real cdf(Real x, Time t) const = 0;
    virtual Real invcdf(Real p, Time t) const = 0;

    virtual ~RiskNeutralDensityCalculator() {}
};

%shared_ptr(BSMRNDCalculator)
class BSMRNDCalculator : public RiskNeutralDensityCalculator {
  public:
    explicit BSMRNDCalculator(
        const boost::shared_ptr<GeneralizedBlackScholesProcess>& process);

    // x = ln(S)
    Real pdf(Real x, Time t) const;
    Real cdf(Real x, Time t) const;
    Real invcdf(Real q, Time t) const;
};

%shared_ptr(CEVRNDCalculator)
class CEVRNDCalculator : public RiskNeutralDensityCalculator {
  public:
    CEVRNDCalculator(Real f0, Real alpha, Real beta);

    Real massAtZero(Time t) const;

    Real pdf(Real f, Time t) const;
    Real cdf(Real f, Time t) const;
    Real invcdf(Real q, Time t) const;
};

%shared_ptr(GBSMRNDCalculator)
class GBSMRNDCalculator : public RiskNeutralDensityCalculator {
public:
    explicit GBSMRNDCalculator(
        const boost::shared_ptr<GeneralizedBlackScholesProcess>& process);

    Real pdf(Real s, Time t) const;
    Real cdf(Real s, Time t) const;
    Real invcdf(Real q, Time t) const;
};

%shared_ptr(HestonRNDCalculator)
class HestonRNDCalculator : public RiskNeutralDensityCalculator {
public:
    HestonRNDCalculator(
        const boost::shared_ptr<HestonProcess>& hestonProcess,
        Real integrationEps= 1e-6,
        Size maxIntegrationIterations = 10000ul);

    // x=ln(S)
    Real pdf(Real x, Time t) const;
    Real cdf(Real x, Time t) const;
    Real invcdf(Real q, Time t) const;
};


%shared_ptr(LocalVolRNDCalculator)
class LocalVolRNDCalculator : public RiskNeutralDensityCalculator {
  public:
#if defined(SWIGPYTHON)
%feature("kwargs") FdmHestonSolver;
#endif
  
    LocalVolRNDCalculator(
        const boost::shared_ptr<Quote>& spot,
        const boost::shared_ptr<YieldTermStructure>& rTS,
        const boost::shared_ptr<YieldTermStructure>& qTS,
        const boost::shared_ptr<LocalVolTermStructure>& localVol,
        Size xGrid = 101, Size tGrid = 51,
        Real x0Density = 0.1,
        Real localVolProbEps = 1e-6,
        Size maxIter = 10000,
        Time gaussianStepSize = -Null<Time>());

    Real pdf(Real x, Time t) const;
    Real cdf(Real x, Time t) const;
    Real invcdf(Real p, Time t) const;

    boost::shared_ptr<Fdm1dMesher> mesher(Time t) const;
#if defined(SWIGPYTHON) || defined(SWIGR)
    %extend {
        std::vector<unsigned int> rescaleTimeSteps() const {
            const std::vector<Size> s = self->rescaleTimeSteps();
            std::vector<unsigned int> tmp(s.size());
            std::copy(s.begin(), s.end(), tmp.begin());
            
            return tmp;
        }
    }
#else 
    %extend {
        std::vector<Size> rescaleTimeSteps() const {
            return self->rescaleTimeSteps();
        }
    }
#endif    
};

%shared_ptr(SquareRootProcessRNDCalculator)
class SquareRootProcessRNDCalculator : public RiskNeutralDensityCalculator {
  public:
    SquareRootProcessRNDCalculator(
        Real v0, Real kappa, Real theta, Real sigma);

    Real pdf(Real v, Time t) const;
    Real cdf(Real v, Time t) const;
    Real invcdf(Real q, Time t) const;

    Real stationary_pdf(Real v) const;
    Real stationary_cdf(Real v) const;
    Real stationary_invcdf(Real q) const;
};


#endif